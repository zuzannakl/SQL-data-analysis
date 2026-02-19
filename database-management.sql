/*
================================================================================
Projekt zawiera:
- Tworzenie i modyfikacja struktury tabel (CREATE, ALTER TABLE).
- Migracje i aktualizacje danych (INSERT INTO, UPDATE).
- Wykorzystanie logiki warunkowej do transformacji cen.
- Zarządzanie spójnością danych poprzez usuwanie rekordów (DELETE).

Bazy danych: 
- Sakila (źródło danych)
- Piaskownica (środowisko testowe do modyfikacji).
================================================================================
*/

-- -----------------------------------------------------------------------------
-- TWORZENIE I MODYFIKACJA STRUKTURY
-- -----------------------------------------------------------------------------

-- Tworzenie nowej tabeli aktorów w schemacie testowym.
CREATE TABLE piaskownica.actor_282258 (
    actor_id INT AUTO_INCREMENT PRIMARY KEY,
    imie VARCHAR(40),
    nazwisko VARCHAR(40),
    last_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Migracja danych z bazy Sakila do nowej tabeli.
INSERT INTO piaskownica.actor_282258 (imie, nazwisko, last_update)
SELECT first_name, last_name, last_update
FROM sakila.actor;

-- Tworzenie tabeli na podstawie wyniku zapytania .
CREATE TABLE piaskownica.film_282258 AS
SELECT * FROM sakila.film;

-- Dynamiczna modyfikacja tabeli .
-- Dodanie kolumny technicznej jako pierwszej w tabeli.
ALTER TABLE piaskownica.actor_282258
ADD COLUMN played_in_100 TINYINT DEFAULT 0;

-- -----------------------------------------------------------------------------
-- AKTUALIZACJE DANYCH
-- -----------------------------------------------------------------------------

-- Aktualizacja flagi na podstawie powiązań w innych tabelach.
-- Oznaczanie aktorów, którzy wystąpili w konkretnym filmie (ID 100).
UPDATE piaskownica.actor_282258
SET played_in_100 = 1
WHERE actor_id IN (
    SELECT actor_id
    FROM sakila.film_actor
    WHERE film_id = 100
);

-- Korekta płatności (Podwyżka o 20% z końcówką .99).
UPDATE sakila.payment
SET amount = 
    CASE
        WHEN ROUND(amount * 1.2, 2) = FLOOR(ROUND(amount * 1.2, 2)) 
            THEN FLOOR(ROUND(amount * 1.2, 2)) + 0.09
        ELSE ROUND(amount * 1.2, 2) + (0.99 - ROUND(amount * 1.2, 2) % 1) 
    END;

-- Synchronizacja statusu klienta.
-- Dezaktywacja klientów, którzy nie dokonali wypożyczenia w określonym dniu.
UPDATE piaskownica.customer c
SET c.status = 'nieaktywny'
WHERE c.customer_id NOT IN (
    SELECT DISTINCT r.customer_id
    FROM sakila.rental r
    WHERE r.rental_date = '2006-02-14'
);

-- -----------------------------------------------------------------------------
-- USUWANIE DANYCH I CZYSZCZENIE BAZY
-- -----------------------------------------------------------------------------

-- Usuwanie rekordów na podstawie podzapytań (np. ostatni ID).
DELETE FROM piaskownica.actor_282258
WHERE actor_id = (SELECT MAX(id) FROM (SELECT actor_id AS id FROM piaskownica.actor_282258) AS t);

-- Usuwanie powiązań.
-- Usuwanie aktorów o tych samych inicjałach imienia i nazwiska.

-- Krok 1: Usuwamy powiązania w tabeli łączącej.
DELETE FROM piaskownica.film_actor_123456
WHERE actor_id IN (
    SELECT actor_id
    FROM piaskownica.actor_123456
    WHERE LEFT(imie, 1) = LEFT(nazwisko, 1)
);

-- Krok 2: Usuwamy rekordy z tabeli głównej.
DELETE FROM piaskownica.actor_123456
WHERE LEFT(imie, 1) = LEFT(nazwisko, 1);

-- Usuwanie filmów z określonej kategorii (np. Drama).
DELETE FROM sakila.film
WHERE film_id IN (
    SELECT fc.film_id
    FROM sakila.film_category fc
    JOIN sakila.category c ON fc.category_id = c.category_id
    WHERE c.name = 'Drama'
);