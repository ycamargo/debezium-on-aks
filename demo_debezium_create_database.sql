SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema demo_debezium_cdc_db
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `demo_debezium_cdc_db` ;

-- -----------------------------------------------------
-- Schema demo_debezium_cdc_db
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `demo_debezium_cdc_db` DEFAULT CHARACTER SET latin1 ;
USE `demo_debezium_cdc_db` ;

-- -----------------------------------------------------
-- Table `demo_debezium_cdc_db`.`order`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `demo_debezium_cdc_db`.`order` ;

CREATE TABLE IF NOT EXISTS `demo_debezium_cdc_db`.`order` (
  `order_id` INT UNSIGNED NOT NULL,
  `date_received` DATETIME NOT NULL,
  `amount` DECIMAL(10,2) NOT NULL,
  `status` VARCHAR(1) NOT NULL,
  PRIMARY KEY (`order_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `demo_debezium_cdc_db`.`order_item`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `demo_debezium_cdc_db`.`order_item` ;

CREATE TABLE IF NOT EXISTS `demo_debezium_cdc_db`.`order_item` (
  `item_id` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `order_id` INT UNSIGNED NOT NULL,
  `product_code` VARCHAR(20) NOT NULL,
  `description` VARCHAR(80) NOT NULL,
  `quantity` INT NOT NULL,
  `price` DECIMAL(10,2) NOT NULL,
  `status` VARCHAR(1) NOT NULL,
  PRIMARY KEY (`item_id`),
  CONSTRAINT `fk_order_item`
    FOREIGN KEY (`order_id`)
    REFERENCES `demo_debezium_cdc_db`.`order` (`order_id`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
