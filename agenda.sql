-- Crear base de datos
CREATE DATABASE agenda;
USE agenda;

-- Tabla de usuarios
CREATE TABLE usuarios (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100),
    email VARCHAR(100),
    ciudad VARCHAR(100)
);

-- Tabla de contactos
CREATE TABLE contactos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    usuario_id INT,
    nombre VARCHAR(100),
    relacion VARCHAR(50),
    FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
);

-- Tabla de teléfonos
CREATE TABLE telefonos (
    id INT AUTO_INCREMENT PRIMARY KEY,
    contacto_id INT,
    numero VARCHAR(20),
    tipo VARCHAR(20),
    FOREIGN KEY (contacto_id) REFERENCES contactos(id)
);

-- Insertar usuarios
INSERT INTO usuarios (nombre, email, ciudad) VALUES
('Ana Pérez', 'ana@example.com', 'Santiago'),
('Luis Gómez', 'luis@example.com', 'Valparaíso'),
('Carla Rojas', 'carla@example.com', 'Concepción');

-- Insertar contactos
INSERT INTO contactos (usuario_id, nombre, relacion) VALUES
(1, 'María Pérez', 'Hermana'),
(1, 'Juan Soto', 'Amigo'),
(2, 'Pedro Gómez', 'Padre'),
(3, 'Laura Rojas', 'Madre');

-- Insertar teléfonos
INSERT INTO telefonos (contacto_id, numero, tipo) VALUES
(1, '912345678', 'Móvil'),
(1, '221234567', 'Fijo'),
(2, '934567890', 'Móvil'),
(3, '945678901', 'Móvil'),
(4, '956789012', 'Móvil');
