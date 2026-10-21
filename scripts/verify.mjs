import { PGlite } from '@electric-sql/pglite';
import { readFile, writeFile, mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const root = fileURLToPath(new URL('../', import.meta.url));
const out = path.join(root, 'outputs');
await mkdir(out, { recursive: true });
const db = new PGlite();
const csv = rows => {
  if (!rows.length) return '';
  const keys = Object.keys(rows[0]);
  const cell = v => v == null ? '' : '"' + (v instanceof Date ? v.toISOString().slice(0,10) : String(v)).replaceAll('"', '""') + '"';
  return [keys.map(cell).join(','), ...rows.map(r => keys.map(k => cell(r[k])).join(','))].join('\n')+'\n';
};
try {
  for (const file of ['01_schema.sql','02_seed.sql','03_views.sql','04_analysis.sql','05_quality_checks.sql']) {
    await db.exec(await readFile(path.join(root, 'sql', file), 'utf8'));
    console.log(`Passed: ${file}`);
  }
  for (const view of ['monthly_performance','category_performance','channel_performance','cohort_retention','product_ranking','customer_rfm','quality_checks']) {
    const order = { monthly_performance:'month',category_performance:'net_sales DESC',channel_performance:'net_sales DESC',cohort_retention:'cohort_month,month_number',product_ranking:'category,category_rank,product_id',customer_rfm:'customer_id',quality_checks:'check_name' }[view];
    const { rows } = await db.query(`SELECT * FROM commerce.${view} ORDER BY ${order}`);
    if (view==='quality_checks' && rows.some(r=>!r.passed)) throw new Error('Quality check failed');
    await writeFile(path.join(out, view+'.csv'), csv(rows));
  }
  // A deliberately unsafe many-side join proves the fixture exposes fan-out.
  const { rows: fanout } = await db.query(`SELECT
    (SELECT sum(i.quantity*i.unit_price-i.discount_amount) FROM commerce.order_items i JOIN commerce.orders o USING(order_id) LEFT JOIN commerce.returns r USING(order_item_id) WHERE o.status='completed') AS unsafe_booked_sales,
    (SELECT sum(booked_sales) FROM commerce.order_economics) AS correct_booked_sales`);
  if (Number(fanout[0].unsafe_booked_sales)<=Number(fanout[0].correct_booked_sales)) throw new Error('Fixture does not expose fan-out');
  await writeFile(path.join(out,'fanout_demonstration.csv'),csv(fanout));
  const plans = await db.exec(await readFile(path.join(root,'sql','06_performance.sql'),'utf8'));
  await writeFile(path.join(out,'query_plans.txt'),plans.filter(p=>p.rows.length).map((p,i)=>`${i===0?'BEFORE':'AFTER'} INDEX\n`+p.rows.map(r=>r['QUERY PLAN']).join('\n')).join('\n\n')+'\n');
  const {rows: totals} = await db.query(`SELECT
    (SELECT count(*) FROM commerce.customers) AS customers,
    (SELECT count(*) FROM commerce.orders) AS orders,
    (SELECT count(*) FROM commerce.order_items) AS items,
    (SELECT count(*) FROM commerce.returns) AS return_events,
    (SELECT sum(booked_sales) FROM commerce.order_economics) AS booked_sales,
    (SELECT sum(refunds) FROM commerce.order_economics) AS refunds,
    (SELECT sum(net_sales) FROM commerce.order_economics) AS net_sales`);
  await writeFile(path.join(out,'totals.csv'),csv(totals));
  await writeFile(path.join(out,'verification.json'),JSON.stringify({engine:'PGlite (PostgreSQL compiled to WebAssembly)',dependency:JSON.parse(await readFile(path.join(root,'package.json'),'utf8')).devDependencies,checks:11,totals:totals[0]},null,2)+'\n');
  console.log(JSON.stringify(totals[0],null,2));
} finally { await db.close(); }
