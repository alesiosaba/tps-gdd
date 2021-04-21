CREATE DATABASE telefonica;
USE telefonica;

CREATE TABLE Provincias(
    codProvincia SMALLINT PRIMARY KEY,
    nombreProvincia VARCHAR(60)
)

CREATE TABLE TiposLlamados(
    codTipoLlamado SMALLINT PRIMARY KEY,
    descrTipoLlamado VARCHAR(60)
)

CREATE TABLE Fabricantes(
    codFabricante SMALLINT PRIMARY KEY,
    nombreFabricante VARCHAR(60) NOT NULL,
    tiempoEntregaPromedio INTEGER
)

CREATE TABLE Productos(
    codProducto SMALLINT PRIMARY KEY,
    codFabricante SMALLINT NOT NULL REFERENCES Fabricantes,
    nomProducto VARCHAR(60) NOT NULL,
    precioUnitario NUMERIC(12,2)
)

CREATE TABLE Clientes(
    codCliente INTEGER PRIMARY KEY,
    nombre VARCHAR(60) NOT NULL,
    apellido VARCHAR(60) NOT NULL,
    nroCuit BIGINTEGER UNIQUE,
    direccion VARCHAR(60),
    codProvincia SMALLINT REFERENCES Provincias,
    ciudad VARCHAR(60),
    codPostal VARCHAR(10),
    telefono1 VARCHAR(60),
    telefono2 VARCHAR(60)
)

CREATE TABLE Llamados(
    idLlamado INTEGER PRIMARY KEY,
    codCliente INTEGER NOT NULL REFERENCES Clientes,
    codTipoLlamado SMALLINT NOT NULL REFERENCES TiposLlamados,
    fechaLlamado DATE,
    telefonoLlamado VARCHAR(60),
    duracionLlamado NUMERIC(12,2)
)

CREATE TABLE Facturas(
    numeroFactura INTEGER PRIMARY KEY,
    codCliente INTEGER NOT NULL REFERENCES Clientes,
    fechaFactura DATE NOT NULL,
    fechaVencimiento DATE NOT NULL CHECK (fechaVencimiento >= fechaFactura)
)

CREATE TABLE ItemsFactura(
    nroItem SMALLINT,
    numeroFactura INTEGER REFERENCES Facturas,
    codProducto INTEGER REFERENCES Productos,
    precioUnitario NUMERIC(12,2),
    cantidad INTEGER NOT NULL CHECK (cantidad >0),
    PRIMARY KEY (numeroroFactura,nroItem)
)