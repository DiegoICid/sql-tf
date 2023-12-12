CREATE SCHEMA IF NOT EXISTS creatorz;

USE creatorz;


# entrega creacion de tablas

USE creatorz;

CREATE TABLE usuarios (
    id INTEGER PRIMARY KEY NOT NULL,
    name varchar(50) NOT NULL,
    following_usr INTEGER,
    is_author BOOLEAN NOT NULL
);

CREATE TABLE siguiendo (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER,
    author_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (author_id) REFERENCES usuarios(id)
);

CREATE TABLE categorias (
    id INTEGER PRIMARY KEY NOT NULL,
    name varchar(50) NOT NULL
);

CREATE TABLE posts (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER,
    date TIMESTAMP,
    text VARCHAR(140) NOT NULL,
    category_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (category_id) REFERENCES categorias(id)
);

CREATE TABLE visualizaciones (
    id INTEGER PRIMARY KEY NOT NULL,
    user_id INTEGER,
    post_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);


# entrega anterior probada y ejecutada en MySQL

# entrega 17 oct

USE creatorz;

insert into usuarios (id, name, following_usr, is_author) values (1, 'Juan Lopez', 2, false);
insert into usuarios (id, name, following_usr, is_author) values (2, 'Carlos Garcia', NULL, true);
insert into usuarios (id, name, following_usr, is_author) values (3, 'Agustina Perez', 2, false);
insert into usuarios (id, name, following_usr, is_author) values (4, 'Mariana Gonzalez', NULL, true);



insert into siguiendo (id, user_id, author_id) values (1, 1, 2);
insert into siguiendo (id, user_id, author_id) values (2, 1, 4);
insert into siguiendo (id, user_id, author_id) values (3, 3, 2);
insert into siguiendo (id, user_id, author_id) values (4, 3, 4);



insert into categorias (id, name) values (1, 'Musica');
insert into categorias (id, name) values (2, 'Literatura');
insert into categorias (id, name) values (3, 'Ciencia');
insert into categorias (id, name) values (4, 'Política');

insert into posts (id, user_id, date, text, category_id) values (1, 2, "2023-10-30 15:25:00", "Este es el post 1 del user 2", 1);
insert into posts (id, user_id, date, text, category_id) values (2, 2, "2023-10-30 15:26:00", "Este es el post 2 del user 2", 2);
insert into posts (id, user_id, date, text, category_id) values (3, 4, "2023-10-30 15:27:00", "Este es el post 1 del user 4", NULL);
insert into posts (id, user_id, date, text, category_id) values (4, 4, "2023-10-30 15:28:00", "Este es el post 2 del user 4", 3);

insert into visualizaciones (id, user_id, post_id) values (1, 1, 1);
insert into visualizaciones (id, user_id, post_id) values (1, 1, 2);
insert into visualizaciones (id, user_id, post_id) values (1, 3, 3);
insert into visualizaciones (id, user_id, post_id) values (1, 3, 4);



# entrega creacion de vistas

USE creatorz;

# Devuelve un ranking de usuarios con mas visualizaciones hechas
CREATE VIEW visualization_ranking AS
(
    SELECT 
	COUNT(vi.id),
    us.name
    FROM usuarios us
    INNER JOIN visualizaciones vi ON vi.user_id = us.id
    GROUP BY us.name
);

# Devuelve un ranking de los posts mas visualizados
CREATE VIEW post_success AS
(
	SELECT 
	COUNT(vi.id) AS visualizaciones,
    po.id AS post_id,
    us.name AS autor
	FROM posts po
	INNER JOIN visualizaciones vi ON vi.post_id = po.id
	LEFT JOIN usuarios us ON us.id = po.user_id
	GROUP BY po.id, us.name
	ORDER BY COUNT(vi.id) DESC
);

# devuelve un listado de autores sin publicaciones
CREATE VIEW idle_author AS
(
	WITH produccion_cte AS 
	(
	SELECT 
		us.name AS autor,
		COUNT(po.id) as cantidad_posts
		FROM usuarios us
		LEFT JOIN posts po ON po.user_id = us.id
		GROUP BY us.name
	)
	SELECT *
	FROM produccion_cte pc 
	WHERE pc.cantidad_posts = 0
);

# devuelve un ranking de autores con mas visualizaciones
CREATE VIEW most_viewed_authors AS
(
	SELECT 
		COUNT(vi.id),
		us.name
		FROM visualizaciones vi
		INNER JOIN posts po ON po.id = vi.post_id 
		LEFT JOIN usuarios us ON us.id = po.user_id
		GROUP BY us.name
		ORDER BY COUNT(vi.id) DESC

);

# Devuelve un ranking de categorias con mas visualizaciones
CREATE VIEW category_success AS
(
	SELECT 
		COUNT(vi.id),
		ca.name
		FROM visualizaciones vi
		INNER JOIN posts po ON po.id = vi.post_id 
		LEFT JOIN categorias ca ON ca.id = po.category_id
		GROUP BY ca.name
		ORDER BY COUNT(vi.id) DESC
);



# entrega de creacion de funciones

# entrega un varchar cortado al maximo de caracteres indicado. Toma el texto original y el maximo como parametros.

DELIMITER //
CREATE FUNCTION TrimToMaxLength(input_string VARCHAR(255), max_length INT) RETURNS VARCHAR(255) DETERMINISTIC NO SQL
BEGIN
    DECLARE trimmed_string VARCHAR(255);
    SET trimmed_string = LEFT(input_string, max_length);
    RETURN trimmed_string;
END//
DELIMITER ;



# entrega un varchar con las iniciales del usuario cuyo id se pasa como parametro
DELIMITER //

CREATE FUNCTION GetUserInitials(user_id INT) RETURNS VARCHAR(255) DETERMINISTIC NO SQL
BEGIN
    DECLARE initials VARCHAR(255);
    DECLARE first_name VARCHAR(255);
    DECLARE last_name VARCHAR(255);
    
    SELECT name INTO initials FROM usuarios WHERE id = user_id;
    
    SET last_name = SUBSTRING_INDEX(initials, ' ', -1);
    SET first_name = SUBSTRING_INDEX(initials, ' ', 1);
    
    SET initials = CONCAT(LEFT(first_name, 1), '. ', LEFT(last_name, 1), '.');
    
    RETURN initials;
END//

DELIMITER ;


# Desafio opcional. Creacion de stored procedures

# Devuelve la totalidad de visualizaciones por autor

DELIMITER //
CREATE PROCEDURE author_total_views (IN autor VARCHAR(50), OUT total_views INT)
BEGIN
    SELECT COUNT(vi.id)
    INTO total_views
    FROM visualizaciones vi
    INNER JOIN posts po ON po.id = vi.post_id 
    LEFT JOIN usuarios us ON us.id = po.user_id
    WHERE us.name = autor;
END//
DELIMITER ;

# prueba
CALL author_total_views('Carlos Garcia', @total_views);
SELECT @total_views;


# Devuelve la fecha de creacion del ultimo post por id de autor

DELIMITER //
CREATE PROCEDURE GetLatestPostByAuthor(IN author_id INTEGER, OUT latest_post_datetime DATETIME)
BEGIN
    SELECT MAX(DATE) INTO latest_post_datetime
    FROM posts
    WHERE user_id = author_id;
END//
DELIMITER ;

# prueba

CALL GetLatestPostByAuthor(2, @latest_post_datetime);
SELECT @latest_post_datetime;


# Creacion de tablas LOGS

CREATE TABLE post_logs (
    id INTEGER PRIMARY KEY NOT NULL,
    date TIMESTAMP NOT NULL,
    type varchar(20) NOT NULL,
    user_id INTEGER NOT NULL,
    post_id INTEGER NOT NULL,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (post_id) REFERENCES posts(id)
);

CREATE TABLE unfollow_logs (
    id INTEGER PRIMARY KEY NOT NULL,
    date TIMESTAMP NOT NULL,
    user_id INTEGER,
    author_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES usuarios(id),
    FOREIGN KEY (author_id) REFERENCES usuarios(id)
);

# Scripts triggers

# Hace un log de los ingresos en post log
DELIMITER //
CREATE TRIGGER trigger_post_log
AFTER INSERT ON posts
FOR EACH ROW
BEGIN
    INSERT INTO post_logs (type, user_id, post_id)
    VALUES ('Insert', NEW.user_id, NEW.id);
END//
DELIMITER ;


# mantiene un registro de los unfollow (borrado de follow)
DELIMITER //
CREATE TRIGGER trigger_unfollow_log
AFTER DELETE ON siguiendo
FOR EACH ROW
BEGIN
    INSERT INTO unfollow_logs (user_id, author_id)
    VALUES (NEW.user_id, NEW.author_id);
END//
DELIMITER ;

# BEFORE Trigger que hace un trim sobre los ingresos para respetar el limite varchar(50)
DELIMITER //
CREATE TRIGGER trigger_trim_name
BEFORE INSERT ON categorias
FOR EACH ROW
BEGIN
    -- Trim name if its length exceeds 50 characters
    IF LENGTH(NEW.name) > 50 THEN
        SET NEW.name = SUBSTRING(NEW.name, 1, 50);
    END IF;
END//
DELIMITER ;


-- Backup de la base de datos

mysqldump -u root -p creatorz > backup.sql


-- Entrega lenguaje TCL

SET AUTOCOMMIT = 0;

-- Caso 1
START TRANSACTION;

DELETE FROM siguiendo WHERE user_id = 1 AND author_id = 2;
DELETE FROM siguiendo WHERE user_id = 2 AND author_id = 1;
--ROLLBACK;
COMMIT;


-- Caso 2
START TRANSACTION;
insert into posts (id, user_id, date, text, category_id) values (5, 2, "2023-11-30 15:25:00", "Post test", 1);
insert into posts (id, user_id, date, text, category_id) values (6, 2, "2023-11-30 15:26:00", "Post test", 2);
insert into posts (id, user_id, date, text, category_id) values (7, 4, "2023-11-30 15:27:00", "Post test", NULL);
insert into posts (id, user_id, date, text, category_id) values (8, 4, "2023-11-30 15:28:00", "Post test", 3);
SAVEPOINT lote_1;
insert into posts (id, user_id, date, text, category_id) values (9, 2, "2023-11-30 15:29:00", "Post test", 1);
insert into posts (id, user_id, date, text, category_id) values (10, 2, "2023-11-30 15:30:00", "Post test", 2);
insert into posts (id, user_id, date, text, category_id) values (11, 4, "2023-11-30 15:31:00", "Post test", NULL);
insert into posts (id, user_id, date, text, category_id) values (12, 4, "2023-11-30 15:32:00", "Post test", 3);
SAVEPOINT lote_2;
--RELEASE SAVEPOINT lote_1;

