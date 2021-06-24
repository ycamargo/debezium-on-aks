-- MySQL Script generated by MySQL Workbench
-- Thu Jun 24 17:05:17 2021
-- Model: New Model    Version: 1.0
-- MySQL Workbench Forward Engineering

SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';

-- -----------------------------------------------------
-- Schema mydb
-- -----------------------------------------------------
-- -----------------------------------------------------
-- Schema tdc_connections_2021_cdc
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS `tdc_connections_2021_cdc` ;

-- -----------------------------------------------------
-- Schema tdc_connections_2021_cdc
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS `tdc_connections_2021_cdc` DEFAULT CHARACTER SET latin1 ;
USE `tdc_connections_2021_cdc` ;

-- -----------------------------------------------------
-- Table `tdc_connections_2021_cdc`.`pedido`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `tdc_connections_2021_cdc`.`pedido` ;

CREATE TABLE IF NOT EXISTS `tdc_connections_2021_cdc`.`pedido` (
  `id_pedido` INT(11) NOT NULL,
  `data_pedido` DATETIME NOT NULL,
  `valor_total_pedido` DECIMAL(10,2) NOT NULL,
  `qtde_itens_pedido` INT(11) NOT NULL,
  `status_pedido` VARCHAR(1) NOT NULL,
  PRIMARY KEY (`id_pedido`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


-- -----------------------------------------------------
-- Table `tdc_connections_2021_cdc`.`item_pedido`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `tdc_connections_2021_cdc`.`item_pedido` ;

CREATE TABLE IF NOT EXISTS `tdc_connections_2021_cdc`.`item_pedido` (
  `id_pedido` INT(11) NOT NULL,
  `id_item_pedido` INT(11) NOT NULL,
  `codigo_item` VARCHAR(20) NOT NULL,
  `descricao_item` VARCHAR(80) NOT NULL,
  `qtde_item` INT(11) NOT NULL,
  `valor_item` DECIMAL(10,2) NOT NULL,
  `status_item` VARCHAR(1) NOT NULL,
  PRIMARY KEY (`id_pedido`, `id_item_pedido`),
  CONSTRAINT `fk_item_pedido`
    FOREIGN KEY (`id_pedido`)
    REFERENCES `tdc_connections_2021_cdc`.`pedido` (`id_pedido`))
ENGINE = InnoDB
DEFAULT CHARACTER SET = latin1;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;