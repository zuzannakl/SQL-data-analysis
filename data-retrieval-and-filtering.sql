/*
================================================================================
Zbiór zapytań SQL przygotowanych na podstawie baz Sakila 
oraz Employees. Projekt demonstruje umiejętności filtrowania danych, 
agregacji, pracy z datami oraz tworzenia podzapytań.

Bazy danych:
- Sakila: System wypożyczalni DVD (klienci, filmy, płatności, inwentarz).
- Employees: Rozbudowany system zarządzania danymi pracowniczymi.
================================================================================
*/

-- -----------------------------------------------------------------------------
-- ANALIZA BAZY SAKILA (FILMY I KLIENCI)
-- -----------------------------------------------------------------------------

-- Analiza brakujących danych w adresach
-- Sprawdzenie rekordów z pustym polem address2, które nie są wartościami NULL.
SELECT COUNT(*) 
FROM sakila.address
WHERE address2 = '' AND address2 IS NOT NULL;

-- Identyfikacja skrajnych roczników produkcji
-- Najstarszy film w bazie
SELECT title, release_year 
FROM sakila.film
ORDER BY release_year ASC 
LIMIT 1;

-- Najmłodszy film w bazie
SELECT title, release_year 
FROM sakila.film
ORDER BY release_year DESC 
LIMIT 1;

-- Zaawansowane stronicowanie
-- Wybranie 10-tego filmu z listy posortowanej malejąco
SELECT title 
FROM sakila.film
ORDER BY title DESC 
LIMIT 1 OFFSET 9;

-- Filtrowanie tekstowe
-- Wyszukiwanie filmów o tematyce SUMO z pominięciem określonych fraz
SELECT title, description 
FROM sakila.film
WHERE description LIKE '% SUMO %'
  AND description NOT LIKE '%SUMO WRESTLER%';

-- Złożone filtrowanie rekordów
-- Zliczanie filmów spełniających specyficzne kryteria ID i opisu
SELECT COUNT(film_id) 
FROM sakila.film
WHERE description LIKE '%SUMO%' 
  AND title NOT LIKE '%A%' 
  AND film_id > length;

-- Analiza powiązań aktorów z konkretnymi tytułami
-- Wyszukiwanie aktorów grających w filmie "WOLVES" (ID 316).
SELECT actor_id, first_name, last_name 
FROM sakila.actor
WHERE actor_id IN (
    SELECT actor_id FROM sakila.film_actor WHERE film_id = 316
);

-- Grupowanie i filtrowanie według ocen (Rating)
-- Wyszukiwanie filmów familijnych (PG) zawierających zwierzęta w opisie.
SELECT title, rating, description 
FROM sakila.film
WHERE rating = 'PG' 
  AND (description LIKE '%cat%' OR description LIKE '%dog%');

-- Najdłuższy film z określonymi cechami dodatkowymi
-- Wykluczenie filmów z usuniętymi scenami i filtrowanie po kategorii wiekowej.
SELECT title, rating, length, film_id 
FROM sakila.film
WHERE (rating = 'PG' OR rating = 'G')
  AND (description LIKE '%cat%' OR description LIKE '%dog%')
  AND special_features NOT LIKE '%Deleted Scenes%'
ORDER BY length DESC 
LIMIT 1;

-- Statystyki inwentarza dla konkretnego tytułu (ID 182).
SELECT store_id, COUNT(film_id) 
FROM sakila.inventory
WHERE film_id = 182
GROUP BY store_id;

-- Zarządzanie lojalnością klientów
-- Filtrowanie aktywnych klientów z określonej grupy ID.
SELECT first_name, last_name, customer_id, email 
FROM sakila.customer
WHERE customer_id IN (470, 337, 430, 256, 325, 102, 259)
  AND active = 1;

-- Pozyskiwanie danych kontaktowych za pomocą podzapytań.
SELECT phone 
FROM sakila.address
WHERE address_id IN (
    SELECT address_id FROM sakila.customer
    WHERE customer_id IN (470, 337, 430, 256, 325, 102, 259)
);

-- Ranking popularności aktorów
-- Zliczanie filmów, w których wystąpili aktorzy o imieniu PENELOPE.
SELECT actor_id, COUNT(film_id) AS liczba_filmow 
FROM sakila.film_actor
WHERE actor_id IN (SELECT actor_id FROM sakila.actor WHERE first_name = 'PENELOPE')
GROUP BY actor_id
ORDER BY liczba_filmow DESC;

-- Analiza finansowa personelu
-- Sumowanie przychodów generowanych przez poszczególnych pracowników.
SELECT staff_id, SUM(amount) AS total_revenue
FROM sakila.payment
GROUP BY staff_id
ORDER BY total_revenue DESC;

-- Raport finansowy dla okresu letniego 2005.
SELECT staff_id, SUM(amount) AS summer_revenue
FROM sakila.payment
WHERE payment_date BETWEEN '2005-07-01' AND '2005-08-31'
GROUP BY staff_id;

-- Monitoring wypożyczeń (Brak zwrotów)
-- Zliczanie aktywnych wypożyczeń w podziale na pracowników.
SELECT staff_id, COUNT(*) AS active_rentals
FROM sakila.rental
WHERE return_date IS NULL
GROUP BY staff_id;

-- Identyfikacja klienta z najstarszym zaległym wypożyczeniem.
SELECT phone FROM sakila.address
WHERE address_id = (
    SELECT address_id FROM sakila.customer
    WHERE customer_id = (
        SELECT customer_id FROM sakila.rental
        WHERE return_date IS NULL
        ORDER BY rental_date ASC
        LIMIT 1
    )
);

-- -----------------------------------------------------------------------------
-- ANALIZA BAZY EMPLOYEES (DANE KADROWE)
-- -----------------------------------------------------------------------------

-- Zliczanie aktywnych pracowników na dzień dzisiejszy.
SELECT COUNT(DISTINCT emp_no) 
FROM employees.dept_emp
WHERE to_date > CURRENT_DATE;

-- Wykaz unikalnych stanowisk w firmie.
SELECT DISTINCT title 
FROM employees.titles;

-- -----------------------------------------------------------------------------
-- WYSZUKIWANIE WZORCÓW I AGREGACJA
-- -----------------------------------------------------------------------------

-- Wyszukiwanie specyficznych struktur imion (4 litery, A na 1 i 3 pozycji)
SELECT * FROM sakila.actor
WHERE first_name LIKE 'A_A_';

-- Filtrowanie inwentarza pod kątem rzadkich tytułów (dokładnie 3 kopie)
SELECT film_id 
FROM sakila.inventory
GROUP BY film_id
HAVING COUNT(*) = 3;

-- Obliczanie rozpiętości długości filmów w kategoriach ratingowych.
-- Wykorzystanie LaTeX do opisu logicznego: $Różnica = max(length) - min(length)$
SELECT rating, MAX(length) - MIN(length) AS roznica_dlugosci 
FROM sakila.film
GROUP BY rating
ORDER BY CAST(rating AS CHAR);