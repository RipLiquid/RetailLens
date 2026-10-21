-- Dedicated schema: does not modify other schemas. Fresh database recommended.
CREATE SCHEMA commerce;
SET search_path TO commerce, public;

CREATE TABLE customers (
    customer_id integer PRIMARY KEY,
    signup_date date NOT NULL,
    acquisition_channel text NOT NULL CHECK (acquisition_channel IN ('Organic','Paid search','Social','Referral')),
    region text NOT NULL
);
CREATE TABLE products (
    product_id integer PRIMARY KEY,
    product_name text NOT NULL,
    category text NOT NULL,
    list_price numeric(12,2) NOT NULL CHECK (list_price > 0),
    unit_cost numeric(12,2) NOT NULL CHECK (unit_cost >= 0)
);
CREATE TABLE orders (
    order_id integer PRIMARY KEY,
    customer_id integer NOT NULL REFERENCES customers,
    order_date date NOT NULL,
    status text NOT NULL CHECK (status IN ('completed','cancelled'))
);
CREATE TABLE order_items (
    order_item_id integer PRIMARY KEY,
    order_id integer NOT NULL REFERENCES orders,
    product_id integer NOT NULL REFERENCES products,
    quantity integer NOT NULL CHECK (quantity > 0),
    unit_price numeric(12,2) NOT NULL CHECK (unit_price > 0),
    unit_cost_at_sale numeric(12,2) NOT NULL CHECK (unit_cost_at_sale >= 0),
    discount_amount numeric(12,2) NOT NULL CHECK (discount_amount >= 0),
    CHECK (discount_amount <= quantity * unit_price)
);
CREATE TABLE returns (
    return_id integer PRIMARY KEY,
    order_item_id integer NOT NULL REFERENCES order_items,
    return_date date NOT NULL,
    returned_quantity integer NOT NULL CHECK (returned_quantity > 0),
    refund_amount numeric(12,2) NOT NULL CHECK (refund_amount >= 0),
    reason text NOT NULL
);
