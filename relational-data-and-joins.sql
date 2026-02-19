/*
================================================================================
Opis: Projekt zawierający poniższe techniki SQL:
- Złączenia tabel.
- Agregację danych z wykorzystaniem funkcji GROUP_CONCAT.
- Obliczenia na datach i czasie (TIMESTAMPDIFF).
- Implementację logiki warunkowej.

Baza danych: Sakila (DVD Rental Database)
================================================================================
*/

-- -----------------------------------------------------------------------------
-- RELACYJNA EKSTRAKCJA DANYCH
-- -----------------------------------------------------------------------------

-- Pełne dane kontaktowe personelu
-- Łączenie tabel staff i address w celu uzyskania informacji o lokalizacji. 
SELECT 
    s.first_name AS imie, 
    s.last_name AS nazwisko, 
    s.email,
    a.address AS adres, 
    a.phone AS nr_telefonu 
FROM sakila.staff s
JOIN sakila.address a ON s.address_id = a.address_id;

-- Hierarchia geograficzna: Miasto - Kraj 
SELECT ci.city, co.country 
FROM sakila.city ci
JOIN sakila.country co ON ci.country_id = co.country_id;

-- Pełny adres (Adres -> Miasto -> Kraj) 
SELECT 
    a.address AS adres,
    ci.city AS miasto,
    co.country AS kraj
FROM sakila.address a
JOIN sakila.city ci ON a.city_id = ci.city_id
JOIN sakila.country co ON ci.country_id = co.country_id;

-- Efektywność operacyjna sklepów
-- Zliczanie wypożyczeń w podziale na sklep i pracownika obsługującego.
SELECT 
    st.store_id AS sklep,
    s.staff_id AS pracownik,
    COUNT(r.rental_id) AS liczba_wypozyczen
FROM sakila.store st
JOIN sakila.staff s ON st.store_id = s.store_id
JOIN sakila.rental r ON s.staff_id = r.staff_id
GROUP BY st.store_id, s.staff_id 
ORDER BY sklep, pracownik;

-- Analiza ról aktorskich w filmach
SELECT 
    a.first_name AS imie,
    a.last_name AS nazwisko,
    f.title AS tytul_filmu
FROM sakila.actor a
JOIN sakila.film_actor fa ON a.actor_id = fa.actor_id
JOIN sakila.film f ON fa.film_id = f.film_id;

-- Profilowanie klienta i przypisanie do managera
-- Przykład wyszukiwania konkretnego klienta wraz z danymi jego managera.
SELECT 
    c.first_name AS imie_klienta,
    c.last_name AS nazwisko_klienta,
    a.phone AS numer_telefonu,
    ci.city AS miasto,
    s.first_name AS imie_managera,
    s.last_name AS nazwisko_managera
FROM sakila.customer c
JOIN sakila.address a ON c.address_id = a.address_id
JOIN sakila.city ci ON a.city_id = ci.city_id
JOIN sakila.store st ON c.store_id = st.store_id
JOIN sakila.staff s ON st.manager_staff_id = s.staff_id
WHERE c.first_name = 'ALAN' AND c.last_name = 'KAHN';

-- -----------------------------------------------------------------------------
-- TRANSFORMACJA I ANALIZA TEKSTU
-- -----------------------------------------------------------------------------

-- Agregacja tekstowa (GROUP_CONCAT)
-- Lista nazwisk aktorów o 2-literowych imionach w formie jednego ciągu znaków. 
SELECT GROUP_CONCAT(last_name ORDER BY last_name SEPARATOR ', ') 
AS "Aktorzy o dwuliterowych imionach"
FROM sakila.actor
WHERE LENGTH(first_name) = 2;

-- Oczyszczanie danych tekstowych
-- Usuwanie znaku 'A' z opisów i filtrowanie wyników. 
SELECT title, REPLACE(description, 'A', '') AS cleaned_description
FROM sakila.film
WHERE REPLACE(description, 'A', '') NOT LIKE "%BORING%"
ORDER BY cleaned_description;

-- Analiza dystryktów w miastach
-- Zliczanie unikalnych dystryktów dla miast posiadających ich więcej niż jeden. 
SELECT city.city_id, COUNT(address.district) AS district_count, 
GROUP_CONCAT(DISTINCT address.district ORDER BY address.district SEPARATOR ' oraz ') AS dystrykty
FROM sakila.city
JOIN sakila.address ON city.city_id = address.city_id
GROUP BY city.city_id
HAVING COUNT(address.district) > 1;

-- -----------------------------------------------------------------------------
-- LOGIKA CZASU I RAPORTOWANIE
-- -----------------------------------------------------------------------------

-- Ekstremalne wartości czasu wypożyczeń (w godzinach)
SELECT 
    MAX(TIMESTAMPDIFF(HOUR, rental_date, return_date)) AS max_godzin,
    MIN(TIMESTAMPDIFF(HOUR, rental_date, return_date)) AS min_godzin
FROM sakila.rental
WHERE return_date IS NOT NULL;

-- Średni czas wypożyczenia
-- Użycie instrukcji CASE do konwersji sekund na czytelny format (dni/godziny/minuty).
SELECT customer.customer_id AS klient_id,
CASE
    WHEN AVG(TIMESTAMPDIFF(SECOND, rental.rental_date, rental.return_date)) >= 86400 THEN 
        CONCAT(ROUND(AVG(TIMESTAMPDIFF(SECOND, rental.rental_date, rental.return_date)) / 86400, 2), ' dni')
    WHEN AVG(TIMESTAMPDIFF(SECOND, rental.rental_date, rental.return_date)) >= 3600 THEN 
        CONCAT(ROUND(AVG(TIMESTAMPDIFF(SECOND, rental.rental_date, rental.return_date)) / 3600, 2), ' godzin')
    ELSE 
        CONCAT(ROUND(AVG(TIMESTAMPDIFF(SECOND, rental.rental_date, rental.return_date)) / 60, 2), ' minut')
END AS sredni_czas
FROM sakila.rental
JOIN sakila.customer ON rental.customer_id = customer.customer_id
WHERE rental.return_date IS NOT NULL
GROUP BY customer.customer_id
ORDER BY AVG(TIMESTAMPDIFF(SECOND, rental.rental_date, rental.return_date)) DESC
LIMIT 1;

-- Obliczanie dopłat za wypożyczenia w określonym terminie. 
SELECT rental.customer_id, CONCAT(ROUND(COUNT(*) * 0.5, 2), '$') AS doplata
FROM sakila.rental
JOIN sakila.payment ON rental.rental_id = payment.rental_id
WHERE rental.rental_date BETWEEN '2005-07-01' AND '2005-08-31'
AND rental.return_date > '2005-08-31'
GROUP BY rental.customer_id;