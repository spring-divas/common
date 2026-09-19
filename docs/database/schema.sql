-- =========================================================
-- IDENTITY
-- =========================================================

CREATE TYPE user_role AS ENUM (
    'CUSTOMER',
    'MANAGER',
    'ADMIN'
);

CREATE TYPE manager_role AS ENUM (
    'OWNER',
    'SENIOR',
    'JUNIOR'
);

CREATE TABLE "user" (
    id          bigint PRIMARY KEY,
    name        varchar(100) NOT NULL,
    surname     varchar(100) NOT NULL,
    email       varchar(255) NOT NULL UNIQUE,
    password    varchar(255) NOT NULL,
    role        user_role NOT NULL DEFAULT 'CUSTOMER'
);

CREATE TABLE venue_manager (
    user_id       bigint NOT NULL REFERENCES "user"(id),
    venue_id      bigint NOT NULL REFERENCES venue(id),
    manager_level manager_role NOT NULL DEFAULT 'JUNIOR'

    PRIMARY KEY (user_id, venue_id)
);

CREATE TABLE user_allergen (
    user_id     bigint NOT NULL REFERENCES "user"(id),
    allergen_id bigint NOT NULL REFERENCES allergen(id),

    PRIMARY KEY (user_id, allergen_id)
);


-- =========================================================
-- STOCK & VENUE & MENU
-- =========================================================

CREATE TABLE ingredient (
    id          bigint PRIMARY KEY,
    name        varchar(100) NOT NULL,
    quantity    integer NOT NULL DEFAULT 0
);

CREATE TABLE allergen (
    id          bigint PRIMARY KEY,
    name        varchar(100) NOT NULL UNIQUE
);

CREATE TABLE ingredient_allergen (
    ingredient_id bigint NOT NULL REFERENCES ingredient(id),
    allergen_id   bigint NOT NULL REFERENCES allergen(id),

    PRIMARY KEY (ingredient_id, allergen_id)
);

CREATE TABLE venue (
    id             bigint PRIMARY KEY,
    name           varchar(150) NOT NULL,
    address        varchar(255) NOT NULL,
    rating         numeric(10, 2) NOT NULL,
    review_number  integer NOT NULL
);

CREATE TABLE venue_table (
    id            bigint PRIMARY KEY,
    venue_id      bigint NOT NULL REFERENCES venue(id),
    is_available  boolean NOT NULL DEFAULT true
);

CREATE TABLE category (
    id       bigint PRIMARY KEY,
    venue_id bigint NOT NULL REFERENCES venue(id),
    name     varchar(150) NOT NULL
);

CREATE TABLE dish (
    id            bigint PRIMARY KEY,
    venue_id      bigint NOT NULL REFERENCES venue(id),
    category_id   bigint NOT NULL REFERENCES category(id),
    name          varchar(150) NOT NULL,
    description   text,
    price         numeric(10, 2) NOT NULL,
    rating        numeric(10, 2) NOT NULL,
    review_number integer NOT NULL
);

CREATE TABLE dish_ingredient (
    dish_id       bigint NOT NULL REFERENCES dish(id),
    ingredient_id bigint NOT NULL REFERENCES ingredient(id),

    PRIMARY KEY (dish_id, ingredient_id)
);


-- =========================================================
-- ORDER
-- =========================================================

CREATE TYPE order_status AS ENUM (
    'NEW',
    'READY',
    'CANCELLED'
);

CREATE TABLE "order" (
    id          bigint PRIMARY KEY,
    user_id     bigint REFERENCES "user"(id),
    table_id    bigint NOT NULL REFERENCES venue_table(id),
    status      order_status NOT NULL DEFAULT 'NEW',
    created_at  timestamp NOT NULL DEFAULT current_timestamp
);

CREATE TABLE order_item (
    id          bigint PRIMARY KEY,
    order_id    bigint NOT NULL REFERENCES "order"(id),
    dish_id     bigint NOT NULL REFERENCES dish(id),
    name        varchar(150) NOT NULL,
    quantity    integer NOT NULL,
    price       numeric(10, 2) NOT NULL
);


-- =========================================================
-- REVIEW
-- =========================================================

CREATE TABLE dish_review (
    id          bigint PRIMARY KEY,
    user_id     bigint NOT NULL REFERENCES "user"(id),
    dish_id     bigint NOT NULL REFERENCES dish(id),
    rating      smallint NOT NULL,
    content     text,
    is_anon     boolean NOT NULL DEFAULT false,
    created_at  timestamp NOT NULL DEFAULT current_timestamp,

    CHECK (rating BETWEEN 1 AND 5)
);

CREATE TABLE venue_review (
    id          bigint PRIMARY KEY,
    user_id     bigint NOT NULL REFERENCES "user"(id),
    venue_id    bigint NOT NULL REFERENCES venue(id),
    rating      smallint NOT NULL,
    content     text,
    is_anon     boolean NOT NULL DEFAULT false,
    created_at  timestamp NOT NULL DEFAULT current_timestamp,

    CHECK (rating BETWEEN 1 AND 5)
);


-- =========================================================
-- PAYMENT
-- =========================================================

CREATE TYPE payment_status AS ENUM (
    'PENDING',
    'PAID',
    'FAILED',
    'REFUNDED'
);

CREATE TABLE payment (
    id          bigint PRIMARY KEY,
    order_id    bigint NOT NULL REFERENCES "order"(id),
    status      payment_status NOT NULL DEFAULT 'PENDING',
    created_at  timestamp NOT NULL DEFAULT current_timestamp
);
