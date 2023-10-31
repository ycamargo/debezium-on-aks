UPDATE `demo_debezium_cdc_db`.`order_item` 
SET `status` = 'P' 
WHERE `order_id` = 4
  AND `product_code` = 'PROD-76';
  
UPDATE `demo_debezium_cdc_db`.`order` 
SET `status` = 'P'
WHERE `order_id` = 4;

DELETE FROM `demo_debezium_cdc_db`.`order_item` 
WHERE `order_id` = 3
  AND `product_code` = 'PROD-22';
  
UPDATE `demo_debezium_cdc_db`.`order` 
SET `amount` = 30.00
WHERE `order_id` = 3;
