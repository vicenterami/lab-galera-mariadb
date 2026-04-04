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

-- Insertar usuarios (Forzando IDs)
INSERT INTO usuarios (id, nombre, email, ciudad) VALUES
(1, 'Ana Pérez', 'ana@example.com', 'Santiago'),
(2, 'Luis Gómez', 'luis@example.com', 'Valparaíso'),
(3, 'Carla Rojas', 'carla@example.com', 'Concepción');

-- Insertar contactos (Forzando IDs)
INSERT INTO contactos (id, usuario_id, nombre, relacion) VALUES
(1, 1, 'María Pérez', 'Hermana'),
(2, 1, 'Juan Soto', 'Amigo'),
(3, 2, 'Pedro Gómez', 'Padre'),
(4, 3, 'Laura Rojas', 'Madre');

-- Insertar teléfonos (Forzando IDs)
INSERT INTO telefonos (id, contacto_id, numero, tipo) VALUES
(1, 1, '912345678', 'Móvil'),
(2, 1, '221234567', 'Fijo'),
(3, 2, '934567890', 'Móvil'),
(4, 3, '945678901', 'Móvil'),
(5, 4, '956789012', 'Móvil');