INSERT INTO `demo_debezium_cdc_db`.`order` (`order_id`, `date_received`, `amount`, `status`)
VALUES (1, sysdate(), 120.35, 'C');
INSERT INTO `demo_debezium_cdc_db`.`order` (`order_id`, `date_received`, `amount`, `status`)
VALUES (2, sysdate(), 23.99, 'P');
INSERT INTO `demo_debezium_cdc_db`.`order` (`order_id`, `date_received`, `amount`, `status`)
VALUES (3, sysdate(), 330.00, 'P');
INSERT INTO `demo_debezium_cdc_db`.`order` (`order_id`, `date_received`, `amount`, `status`)
VALUES (4, sysdate(), 99.99, 'C');
INSERT INTO `demo_debezium_cdc_db`.`order` (`order_id`, `date_received`, `amount`, `status`)
VALUES (5, sysdate(), 200.00, 'D');

INSERT INTO `demo_debezium_cdc_db`.`order_item` (`order_id`, `product_code`, `description`, `quantity`, `price`, `status`)
VALUES (1, 'PROD-01', 'Product 1 of Order 1', 1, 120.35, 'C');
INSERT INTO `demo_debezium_cdc_db`.`order_item` (`order_id`, `product_code`, `description`, `quantity`, `price`, `status`)
VALUES (2, 'PROD-99', 'Product 99 of Order 2', 1, 23.99, 'S');
INSERT INTO `demo_debezium_cdc_db`.`order_item` (`order_id`, `product_code`, `description`, `quantity`, `price`, `status`)
VALUES (3, 'PROD-22', 'Product 22 of Order 3', 3, 110.00, 'S');
INSERT INTO `demo_debezium_cdc_db`.`order_item` (`order_id`, `product_code`, `description`, `quantity`, `price`, `status`)
VALUES (4, 'PROD-76', 'Product 76 of Order 4', 1, 99.99, 'C');
INSERT INTO `demo_debezium_cdc_db`.`order_item` (`order_id`, `product_code`, `description`, `quantity`, `price`, `status`)
VALUES (5, 'PROD-21', 'Product 21 of Order 5', 1, 120.00, 'D');
INSERT INTO `demo_debezium_cdc_db`.`order_item` (`order_id`, `product_code`, `description`, `quantity`, `price`, `status`)
VALUES (5, 'PROD-25', 'Product 25 of Order 5', 1, 80.00, 'D');


