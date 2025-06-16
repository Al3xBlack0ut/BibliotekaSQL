-- =====================================================
-- SYSTEM ZARZĄDZANIA BIBLIOTEKĄ
-- =====================================================

-- Usunięcie istniejących tabel 
DROP TABLE kary CASCADE CONSTRAINTS;
DROP TABLE rezerwacje CASCADE CONSTRAINTS;
DROP TABLE wypozyczenia CASCADE CONSTRAINTS;
DROP TABLE egzemplarze CASCADE CONSTRAINTS;
DROP TABLE ksiazka_autor CASCADE CONSTRAINTS;
DROP TABLE ksiazki CASCADE CONSTRAINTS;
DROP TABLE autorzy CASCADE CONSTRAINTS;
DROP TABLE czytelnicy CASCADE CONSTRAINTS;
DROP TABLE pracownicyBiblioteki CASCADE CONSTRAINTS;

-- Usunięcie sekwencji
DROP SEQUENCE seq_czytelnik_id;
DROP SEQUENCE seq_pracownik_id;
DROP SEQUENCE seq_autor_id;
DROP SEQUENCE seq_ksiazka_id;

-- =====================================================
-- TWORZENIE SEKWENCJI
-- =====================================================

CREATE SEQUENCE seq_czytelnik_id START WITH 1000000 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_pracownik_id START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_autor_id START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_ksiazka_id START WITH 1 INCREMENT BY 1 NOCACHE;

-- =====================================================
-- TWORZENIE TABEL
-- =====================================================

-- Tabela CZYTELNICY
CREATE TABLE czytelnicy (
    nr_karty          NUMBER(8) PRIMARY KEY,
    imie             VARCHAR2(50) NOT NULL,
    nazwisko         VARCHAR2(50) NOT NULL,
    data_urodzenia   DATE NOT NULL,
    email            VARCHAR2(100) UNIQUE,
    telefon          VARCHAR2(15),
    ulica            VARCHAR2(100),
    miasto           VARCHAR2(50),
    kod_pocztowy     VARCHAR2(6),
    data_wydania_karty DATE DEFAULT SYSDATE,
    data_waznosci_karty DATE NOT NULL,
    typ_karty        VARCHAR2(20) NOT NULL,
    status_karty     VARCHAR2(20) DEFAULT 'aktywna',
    
    CONSTRAINT chk_email_czyt CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT chk_kod_pocztowy_czyt CHECK (REGEXP_LIKE(kod_pocztowy, '^\d{2}-\d{3}$')),
    CONSTRAINT chk_typ_karty CHECK (typ_karty IN ('normalna', 'studencka', 'senior', 'dziecięca')),
    CONSTRAINT chk_status_karty CHECK (status_karty IN ('aktywna', 'zawieszona', 'anulowana')),
    CONSTRAINT chk_waznosc_karty CHECK (data_waznosci_karty > data_wydania_karty)
);

-- Tabela AUTORZY
CREATE TABLE autorzy (
    id_autora      NUMBER(6) PRIMARY KEY,
    imie          VARCHAR2(50) NOT NULL,
    nazwisko      VARCHAR2(50) NOT NULL,
    data_urodzenia DATE,
    data_smierci  DATE,
    narodowosc    VARCHAR2(50),
    biografia     CLOB,
    
    CONSTRAINT chk_daty_autor CHECK (data_smierci IS NULL OR data_smierci >= data_urodzenia)
);


-- Tabela KSIĄŻKI
CREATE TABLE ksiazki (
 id_ksiazki NUMBER(8) PRIMARY KEY,
 tytul VARCHAR2(200) NOT NULL,
 podtytul VARCHAR2(200),
 isbn VARCHAR2(17) UNIQUE,
 rok_wydania NUMBER(4),
 wydawnictwo VARCHAR2(100),
 liczba_stron NUMBER(5),
 jezyk VARCHAR2(30) DEFAULT 'polski',
 opis_ksiazki CLOB,
CONSTRAINT chk_isbn CHECK (isbn IS NULL OR REGEXP_LIKE(isbn, '^\d{3}-\d{2}-\d{4}-\d{3}-\d$')),
CONSTRAINT chk_rok_wydania CHECK (rok_wydania BETWEEN 1000 AND 2030),
CONSTRAINT chk_strony CHECK (liczba_stron > 0)
);

-- Tabela PRACOWNICYBIBLIOTEKI
CREATE TABLE pracownicyBiblioteki (
    id_pracownika    NUMBER(6) PRIMARY KEY,
    imie            VARCHAR2(50) NOT NULL,
    nazwisko        VARCHAR2(50) NOT NULL,
    data_urodzenia  DATE NOT NULL,
    email           VARCHAR2(100) UNIQUE,
    telefon         VARCHAR2(15),
    ulica           VARCHAR2(100),
    miasto          VARCHAR2(50),
    kod_pocztowy    VARCHAR2(6),
    stanowisko      VARCHAR2(50) NOT NULL,
    pensja          NUMBER(8,2) NOT NULL,
    data_zatrudnienia DATE DEFAULT SYSDATE,
    
    CONSTRAINT chk_email_prac CHECK (REGEXP_LIKE(email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$')),
    CONSTRAINT chk_pensja_prac CHECK (pensja > 0),
    CONSTRAINT chk_kod_pocztowy_prac CHECK (REGEXP_LIKE(kod_pocztowy, '^\d{2}-\d{3}$')),
    CONSTRAINT chk_stanowisko CHECK (stanowisko IN ('bibliotekarz', 'kierownik', 'asystent', 'administrator'))
);

-- Tabela KSIĄŻKA_AUTOR (związek M:N)
CREATE TABLE ksiazka_autor (
    id_ksiazki NUMBER(8),
    id_autora  NUMBER(6),
    rola_autora VARCHAR2(50) DEFAULT 'autor',
    
    PRIMARY KEY (id_ksiazki, id_autora),
    CONSTRAINT fk_ka_ksiazka FOREIGN KEY (id_ksiazki) 
        REFERENCES ksiazki(id_ksiazki) ON DELETE CASCADE,
    CONSTRAINT fk_ka_autor FOREIGN KEY (id_autora) 
        REFERENCES autorzy(id_autora) ON DELETE CASCADE,
    CONSTRAINT chk_rola_autora CHECK (rola_autora IN ('autor', 'współautor', 'tłumacz', 'redaktor', 'ilustrator'))
);


-- Tabela EGZEMPLARZE (encja słaba)
CREATE TABLE egzemplarze (
    id_ksiazki      NUMBER(8),
    nr_egzemplarza  NUMBER(3),
    stan_egzemplarza VARCHAR2(20) DEFAULT 'nowy',
    lokalizacja     VARCHAR2(20), -- np. "A-12-3" (regał-półka-pozycja)
    data_zakupu     DATE DEFAULT SYSDATE,
    cena_zakupu     NUMBER(8,2),
    status_dostepnosci VARCHAR2(20) DEFAULT 'dostępny',
    
    PRIMARY KEY (id_ksiazki, nr_egzemplarza),
    CONSTRAINT fk_egz_ksiazka FOREIGN KEY (id_ksiazki) 
        REFERENCES ksiazki(id_ksiazki) ON DELETE CASCADE,
    CONSTRAINT chk_stan_egz CHECK (stan_egzemplarza IN ('nowy', 'dobry', 'zniszczony', 'uszkodzony', 'do_naprawy')),
    CONSTRAINT chk_cena_zakupu CHECK (cena_zakupu >= 0),
    CONSTRAINT chk_status_dostepnosci CHECK (status_dostepnosci IN ('dostępny', 'wypożyczony', 'zarezerwowany', 'w_naprawie', 'wycofany'))
);

-- Tabela WYPOŻYCZENIA (encja słaba)
CREATE TABLE wypozyczenia (
    nr_karty             NUMBER(8),
    id_ksiazki           NUMBER(8),
    nr_egzemplarza       NUMBER(3),
    data_wypozyczenia    DATE DEFAULT SYSDATE,
    planowana_data_zwrotu DATE NOT NULL,
    rzeczywista_data_zwrotu DATE,
    id_pracownika_wyp    NUMBER(6) NOT NULL,
    id_pracownika_zwr    NUMBER(6),
    przedluzenia         NUMBER(1) DEFAULT 0,
    uwagi               VARCHAR2(500),
    
    PRIMARY KEY (nr_karty, id_ksiazki, nr_egzemplarza, data_wypozyczenia),
    CONSTRAINT fk_wyp_czytelnik FOREIGN KEY (nr_karty) 
        REFERENCES czytelnicy(nr_karty) ON DELETE CASCADE,
    CONSTRAINT fk_wyp_egzemplarz FOREIGN KEY (id_ksiazki, nr_egzemplarza) 
        REFERENCES egzemplarze(id_ksiazki, nr_egzemplarza) ON DELETE CASCADE,
    CONSTRAINT fk_wyp_prac_wyp FOREIGN KEY (id_pracownika_wyp) 
        REFERENCES pracownicyBiblioteki(id_pracownika),
    CONSTRAINT fk_wyp_prac_zwr FOREIGN KEY (id_pracownika_zwr) 
        REFERENCES pracownicyBiblioteki(id_pracownika),
    CONSTRAINT chk_daty_wyp CHECK (planowana_data_zwrotu > data_wypozyczenia),
    CONSTRAINT chk_data_zwrotu CHECK (rzeczywista_data_zwrotu IS NULL OR rzeczywista_data_zwrotu >= data_wypozyczenia),
    CONSTRAINT chk_przedluzenia CHECK (przedluzenia BETWEEN 0 AND 3)
);

-- Tabela REZERWACJE (encja słaba)
CREATE TABLE rezerwacje (
    nr_karty                 NUMBER(8),
    id_ksiazki              NUMBER(8),
    nr_egzemplarza          NUMBER(3),
    data_rezerwacji         DATE DEFAULT SYSDATE,
    data_waznosci_rezerwacji DATE NOT NULL,
    status_rezerwacji       VARCHAR2(20) DEFAULT 'aktywna',
    uwagi                   VARCHAR2(500),
    
    PRIMARY KEY (nr_karty, id_ksiazki, nr_egzemplarza, data_rezerwacji),
    CONSTRAINT fk_rez_czytelnik FOREIGN KEY (nr_karty) 
        REFERENCES czytelnicy(nr_karty) ON DELETE CASCADE,
    CONSTRAINT fk_rez_egzemplarz FOREIGN KEY (id_ksiazki, nr_egzemplarza) 
        REFERENCES egzemplarze(id_ksiazki, nr_egzemplarza) ON DELETE CASCADE,
    CONSTRAINT chk_status_rez CHECK (status_rezerwacji IN ('aktywna', 'zrealizowana', 'anulowana', 'wygasła')),
    CONSTRAINT chk_waznosc_rez CHECK (data_waznosci_rezerwacji > data_rezerwacji)
);

-- Tabela KARY (encja słaba)
CREATE TABLE kary (
    id_kary         NUMBER(8) GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    nr_karty       NUMBER(8),
    data_nalozenia DATE DEFAULT SYSDATE,
    kwota_kary     NUMBER(8,2) NOT NULL,
    powod_kary     VARCHAR2(200) NOT NULL,
    status_kary    VARCHAR2(20) DEFAULT 'niezapłacona',
    data_zaplaty   DATE,
    id_pracownika  NUMBER(6) NOT NULL,
    
    CONSTRAINT fk_kara_czytelnik FOREIGN KEY (nr_karty) 
        REFERENCES czytelnicy(nr_karty) ON DELETE CASCADE,
    CONSTRAINT fk_kara_pracownik FOREIGN KEY (id_pracownika) 
        REFERENCES pracownicyBiblioteki(id_pracownika),
    CONSTRAINT chk_kwota_kary CHECK (kwota_kary > 0),
    CONSTRAINT chk_status_kary CHECK (status_kary IN ('niezapłacona', 'zapłacona', 'umorzona')),
    CONSTRAINT chk_data_zaplaty CHECK (data_zaplaty IS NULL OR data_zaplaty >= data_nalozenia)
);

-- =====================================================
-- TRIGGERY ZAPEWNIAJĄCE INTEGRALNOŚĆ
-- =====================================================

-- Trigger 1: Sprawdza dostępność przy rezerwacji
CREATE OR REPLACE TRIGGER trg_rezerwacja_dostepnosc
    BEFORE INSERT ON rezerwacje
    FOR EACH ROW
DECLARE
    v_status VARCHAR2(20);
    v_wypozyczony NUMBER;
BEGIN
    -- Sprawdź status dostępności egzemplarza
    SELECT status_dostepnosci 
    INTO v_status
    FROM egzemplarze 
    WHERE id_ksiazki = :NEW.id_ksiazki 
      AND nr_egzemplarza = :NEW.nr_egzemplarza;
    
    -- Sprawdź czy egzemplarz nie jest wypożyczony
    SELECT COUNT(*)
    INTO v_wypozyczony
    FROM wypozyczenia
    WHERE id_ksiazki = :NEW.id_ksiazki 
      AND nr_egzemplarza = :NEW.nr_egzemplarza
      AND rzeczywista_data_zwrotu IS NULL;
    
    IF v_status != 'dostępny' OR v_wypozyczony > 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Nie można zarezerwować: egzemplarz jest wypożyczony lub niedostępny');
    END IF;
    
    -- Ustaw status na 'zarezerwowany'
    UPDATE egzemplarze 
    SET status_dostepnosci = 'zarezerwowany'
    WHERE id_ksiazki = :NEW.id_ksiazki 
      AND nr_egzemplarza = :NEW.nr_egzemplarza;
END;
/

-- Trigger 2: Sprawdza dostępność przy wypożyczeniu
CREATE OR REPLACE TRIGGER trg_wypozyczenie_dostepnosc
    BEFORE INSERT ON wypozyczenia
    FOR EACH ROW
DECLARE
    v_status VARCHAR2(20);
    v_zarezerwowany NUMBER;
    v_ma_rezerwacje NUMBER;
BEGIN
    -- Sprawdź aktualny status egzemplarza
    SELECT status_dostepnosci
    INTO v_status
    FROM egzemplarze
    WHERE id_ksiazki = :NEW.id_ksiazki
      AND nr_egzemplarza = :NEW.nr_egzemplarza;
    
    -- Sprawdź czy egzemplarz jest już wypożyczony
    IF v_status = 'wypożyczony' THEN
        RAISE_APPLICATION_ERROR(-20001, 
            'Nie można wypożyczyć: egzemplarz jest już wypożyczony');
    END IF;
    
    -- Sprawdź czy zarezerwowany przez kogoś innego
    SELECT COUNT(*)
    INTO v_zarezerwowany
    FROM rezerwacje
    WHERE id_ksiazki = :NEW.id_ksiazki
      AND nr_egzemplarza = :NEW.nr_egzemplarza
      AND status_rezerwacji = 'aktywna'
      AND nr_karty != :NEW.nr_karty;
    
    IF v_status = 'zarezerwowany' AND v_zarezerwowany > 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Nie można wypożyczyć: egzemplarz zarezerwowany przez innego czytelnika');
    END IF;
    
    -- Sprawdź czy użytkownik ma aktywną rezerwację na ten egzemplarz
    SELECT COUNT(*)
    INTO v_ma_rezerwacje
    FROM rezerwacje
    WHERE id_ksiazki = :NEW.id_ksiazki
      AND nr_egzemplarza = :NEW.nr_egzemplarza
      AND nr_karty = :NEW.nr_karty
      AND status_rezerwacji = 'aktywna';
    
    -- Ustaw status na 'wypożyczony'
    UPDATE egzemplarze
    SET status_dostepnosci = 'wypożyczony'
    WHERE id_ksiazki = :NEW.id_ksiazki
      AND nr_egzemplarza = :NEW.nr_egzemplarza;
    
    -- Zrealizuj rezerwację jeśli istnieje
    IF v_ma_rezerwacje > 0 THEN
        UPDATE rezerwacje
        SET status_rezerwacji = 'zrealizowana',
            data_realizacji = SYSDATE
        WHERE id_ksiazki = :NEW.id_ksiazki
          AND nr_egzemplarza = :NEW.nr_egzemplarza
          AND nr_karty = :NEW.nr_karty
          AND status_rezerwacji = 'aktywna';
    END IF;

-- Trigger 3: Przywraca dostępność przy zwrocie
CREATE OR REPLACE TRIGGER trg_zwrot_ksiazki
    AFTER UPDATE OF rzeczywista_data_zwrotu ON wypozyczenia
    FOR EACH ROW
    WHEN (NEW.rzeczywista_data_zwrotu IS NOT NULL AND OLD.rzeczywista_data_zwrotu IS NULL)
BEGIN
    UPDATE egzemplarze 
    SET status_dostepnosci = 'dostępny'
    WHERE id_ksiazki = :NEW.id_ksiazki 
      AND nr_egzemplarza = :NEW.nr_egzemplarza;
END;
/

-- Trigger 4: Przywraca dostępność przy anulowaniu rezerwacji
CREATE OR REPLACE TRIGGER trg_anulowanie_rezerwacji
    AFTER UPDATE OF status_rezerwacji ON rezerwacje
    FOR EACH ROW
    WHEN (NEW.status_rezerwacji IN ('anulowana', 'wygasła') 
          AND OLD.status_rezerwacji = 'aktywna')
BEGIN
    UPDATE egzemplarze 
    SET status_dostepnosci = 'dostępny'
    WHERE id_ksiazki = :NEW.id_ksiazki 
      AND nr_egzemplarza = :NEW.nr_egzemplarza;
END;
/

-- Trigger 5: Automatyczne naliczanie kar za przetrzymanie
CREATE OR REPLACE TRIGGER trg_kara_za_przetrzymanie
    AFTER UPDATE OF rzeczywista_data_zwrotu ON wypozyczenia
    FOR EACH ROW
    WHEN (NEW.rzeczywista_data_zwrotu IS NOT NULL AND OLD.rzeczywista_data_zwrotu IS NULL)
DECLARE
    v_dni_opoznienia NUMBER;
    v_kwota_kary NUMBER(8,2);
BEGIN
    -- Oblicz dni opóźnienia
    v_dni_opoznienia := :NEW.rzeczywista_data_zwrotu - :NEW.planowana_data_zwrotu;
    
    -- Jeśli książka zwrócona z opóźnieniem, nałóż karę
    IF v_dni_opoznienia > 0 THEN
        v_kwota_kary := v_dni_opoznienia * 0.50; -- 50 groszy za dzień
        
        INSERT INTO kary (nr_karty, data_nalozenia, kwota_kary, powod_kary, id_pracownika)
        VALUES (:NEW.nr_karty, SYSDATE, v_kwota_kary, 
                'Przetrzymanie książki o ' || v_dni_opoznienia || ' dni', 
                :NEW.id_pracownika_zwr);
    END IF;
END;
/
-- ============================================================================================================================================================
-- ============================================================================================================================================================
-- ============================================================================================================================================================
-- WIDOKI 

-- Widok: Dostępne egzemplarze
CREATE OR REPLACE VIEW v_dostepne_egzemplarze AS
SELECT 
    k.id_ksiazki,
    k.tytul,
    k.isbn,
    e.nr_egzemplarza,
    e.status_dostepnosci,
    e.lokalizacja,
    e.stan_egzemplarza,
    LISTAGG(a.imie || ' ' || a.nazwisko, ', ') 
        WITHIN GROUP (ORDER BY a.nazwisko, a.imie) AS autorzy
FROM ksiazki k
JOIN egzemplarze e ON k.id_ksiazki = e.id_ksiazki
LEFT JOIN ksiazka_autor ka ON k.id_ksiazki = ka.id_ksiazki
LEFT JOIN autorzy a ON ka.id_autora = a.id_autora
WHERE e.status_dostepnosci = 'dostępny'
GROUP BY k.id_ksiazki, k.tytul, k.isbn, e.nr_egzemplarza, 
         e.status_dostepnosci, e.lokalizacja, e.stan_egzemplarza
ORDER BY k.tytul, e.nr_egzemplarza;


-- Widok: Aktywne wypożyczenia
CREATE OR REPLACE VIEW v_aktywne_wypozyczenia AS
SELECT 
    c.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    k.tytul,
    w.nr_egzemplarza,
    w.data_wypozyczenia,
    w.planowana_data_zwrotu,
    CASE 
        WHEN w.planowana_data_zwrotu < SYSDATE THEN 'PRZETERMINOWANE'
        WHEN w.planowana_data_zwrotu - SYSDATE <= 3 THEN 'PRZYPOMNIENIE'
        ELSE 'AKTUALNE'
    END AS status_zwrotu,
    (SYSDATE - w.planowana_data_zwrotu) AS dni_opoznienia
FROM wypozyczenia w
JOIN czytelnicy c ON w.nr_karty = c.nr_karty
JOIN ksiazki k ON w.id_ksiazki = k.id_ksiazki
WHERE w.rzeczywista_data_zwrotu IS NULL
ORDER BY w.planowana_data_zwrotu;

-- Widok: Statystyki czytelników
CREATE OR REPLACE VIEW v_statystyki_czytelnikow AS
SELECT 
    c.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    COUNT(w.nr_karty) AS liczba_wypozyczen,
    COUNT(CASE WHEN w.rzeczywista_data_zwrotu IS NULL THEN 1 END) AS aktywne_wypozyczenia,
    NVL(SUM(k.kwota_kary), 0) AS suma_kar,
    COUNT(CASE WHEN k.status_kary = 'niezapłacona' THEN 1 END) AS niezaplacone_kary
FROM czytelnicy c
LEFT JOIN wypozyczenia w ON c.nr_karty = w.nr_karty
LEFT JOIN kary k ON c.nr_karty = k.nr_karty
WHERE c.status_karty = 'aktywna'
GROUP BY c.nr_karty, c.imie, c.nazwisko
ORDER BY liczba_wypozyczen DESC;

-- ============================================================================================================================================================
-- ============================================================================================================================================================
-- ============================================================================================================================================================
-- DANE 

-- Czytelnicy
INSERT INTO czytelnicy VALUES (1000001, 'Anna', 'Kowalska', TO_DATE('1990-04-12','YYYY-MM-DD'), 'anna.kowalska@example.com', '123456789', 'Lipowa 10', 'Warszawa', '00-001', SYSDATE, SYSDATE + 365, 'normalna', 'aktywna');
INSERT INTO czytelnicy VALUES (1000002, 'Jan', 'Nowak', TO_DATE('1985-10-30','YYYY-MM-DD'), 'jan.nowak@example.com', '987654321', 'Długa 5', 'Kraków', '31-002', SYSDATE, SYSDATE + 365, 'studencka', 'aktywna');

-- Pracownicy
INSERT INTO pracownicyBiblioteki VALUES (1, 'Magdalena', 'Zielińska', TO_DATE('1975-06-15','YYYY-MM-DD'), 'm.zielinska@biblioteka.pl', '555123456', 'Biblioteczna 1', 'Gdańsk', '80-001', 'bibliotekarz', 4500, SYSDATE);
INSERT INTO pracownicyBiblioteki VALUES (2, 'Piotr', 'Wiśniewski', TO_DATE('1980-02-20','YYYY-MM-DD'), 'p.wisniewski@biblioteka.pl', '555987654', 'Morska 3', 'Sopot', '81-001', 'kierownik', 6000, SYSDATE);

-- Autorzy
INSERT INTO autorzy VALUES (1, 'Henryk', 'Sienkiewicz', TO_DATE('1846-05-05','YYYY-MM-DD'), TO_DATE('1916-11-15','YYYY-MM-DD'), 'polska', NULL);
INSERT INTO autorzy VALUES (2, 'J.K.', 'Rowling', TO_DATE('1965-07-31','YYYY-MM-DD'), NULL, 'brytyjska', NULL);
INSERT INTO autorzy VALUES (3, 'Bolesław', 'Prus', TO_DATE('1847-08-20','YYYY-MM-DD'), TO_DATE('1912-05-19','YYYY-MM-DD'), 'polska', NULL);

-- Książki
INSERT INTO ksiazki VALUES (1, 'Quo Vadis', NULL, '978-83-1234-567-0', 1896, 'PWN', 450, 'polski', 'Powieść historyczna');
INSERT INTO ksiazki VALUES (2, 'Harry Potter i Kamień Filozoficzny', NULL, '978-83-4321-123-4', 1997, 'Media Rodzina', 320, 'polski', 'Powieść fantasy dla młodzieży');
INSERT INTO ksiazki VALUES (3, 'Lalka', NULL, '978-83-5555-111-1', 1890, 'Państwowy Instytut Wydawniczy', 680, 'polski', 'Powieść realistyczna');

-- Relacja ksiazka_autor
INSERT INTO ksiazka_autor VALUES (1, 1, 'autor');
INSERT INTO ksiazka_autor VALUES (2, 2, 'autor');
INSERT INTO ksiazka_autor VALUES (3, 3, 'autor');

-- Egzemplarze
INSERT INTO egzemplarze VALUES (1, 1, 'dobry', 'A-01-01', SYSDATE - 200, 25.99, 'dostępny');
INSERT INTO egzemplarze VALUES (2, 1, 'nowy', 'A-01-02', SYSDATE - 100, 39.99, 'dostępny');
INSERT INTO egzemplarze VALUES (3, 1, 'dobry', 'B-02-04', SYSDATE - 50, 34.50, 'dostępny');

-- Wypożyczenia
    -- Anna Kowalska wypożycza "Quo Vadis"
INSERT INTO wypozyczenia (
    nr_karty, id_ksiazki, nr_egzemplarza, 
    data_wypozyczenia, planowana_data_zwrotu, 
    rzeczywista_data_zwrotu, id_pracownika_wyp, id_pracownika_zwr, przedluzenia, uwagi
) VALUES (
    1000001, 1, 1, 
    SYSDATE - 20, SYSDATE - 10, 
    SYSDATE - 5, 1, 1, 1, 'Zwrócono z opóźnieniem'
);

    -- Jan Nowak wypożycza "Harry Potter" — nadal nie zwrócił
INSERT INTO wypozyczenia (
    nr_karty, id_ksiazki, nr_egzemplarza, 
    data_wypozyczenia, planowana_data_zwrotu, 
    rzeczywista_data_zwrotu, id_pracownika_wyp, id_pracownika_zwr, przedluzenia, uwagi
) VALUES (
    1000002, 2, 1, 
    SYSDATE - 7, SYSDATE + 7, 
    NULL, 1, NULL, 0, 'Brak'
);

-- Rezerwacje
    -- Anna Kowalska rezerwuje "Lalkę"
INSERT INTO rezerwacje (
    nr_karty, id_ksiazki, nr_egzemplarza, 
    data_rezerwacji, data_waznosci_rezerwacji, 
    status_rezerwacji, uwagi
) VALUES (
    1000001, 3, 1, 
    SYSDATE, SYSDATE + 7, 
    'aktywna', 'Chce przeczytać w przyszłym tygodniu'
);

-- ============================================================================================================================================================
-- ============================================================================================================================================================
-- ============================================================================================================================================================
-- FUNKCJA: ZWROT KSIĄŻKI Z AUTOMATYCZNYM NALICZENIEM KARY
-- =====================================================
-- Parametry wejściowe (do podstawienia w zapytaniach):
-- @nr_karty = 1000001 (Anna Kowalska)
-- @id_ksiazki = 1 (Quo Vadis)  
-- @nr_egzemplarza = 1
-- @data_wypozyczenia = aktualna data wypożyczenia
-- @id_pracownika_zwr = 2 (Piotr Wiśniewski - przyjmuje zwrot)

-- =====================================================
-- KROK 1: WERYFIKACJA AKTYWNEGO WYPOŻYCZENIA
-- =====================================================

-- Sprawdź czy istnieje aktywne wypożyczenie dla podanych parametrów
SELECT 
    w.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    k.tytul AS tytul_ksiazki,
    w.nr_egzemplarza,
    w.data_wypozyczenia,
    w.planowana_data_zwrotu,
    w.przedluzenia,
    CASE 
        WHEN w.planowana_data_zwrotu < SYSDATE THEN 
            CEIL(SYSDATE - w.planowana_data_zwrotu) || ' dni opóźnienia'
        ELSE 
            'Zwrot w terminie'
    END AS status_zwrotu
FROM wypozyczenia w
JOIN czytelnicy c ON w.nr_karty = c.nr_karty
JOIN ksiazki k ON w.id_ksiazki = k.id_ksiazki
WHERE w.nr_karty = 1000001
  AND w.id_ksiazki = 1
  AND w.nr_egzemplarza = 1
  AND w.rzeczywista_data_zwrotu IS NULL;

-- =====================================================
-- KROK 2: SPRAWDZENIE STANU CZYTELNIKA
-- =====================================================

-- Sprawdź status karty czytelnika i jego aktualne zadłużenia
SELECT 
    c.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    c.status_karty,
    c.data_waznosci_karty,
    COUNT(CASE WHEN k.status_kary = 'niezapłacona' THEN 1 END) AS niezaplacone_kary,
    NVL(SUM(CASE WHEN k.status_kary = 'niezapłacona' THEN k.kwota_kary ELSE 0 END), 0) AS suma_zaleglosci
FROM czytelnicy c
LEFT JOIN kary k ON c.nr_karty = k.nr_karty
WHERE c.nr_karty = 1000001
GROUP BY c.nr_karty, c.imie, c.nazwisko, c.status_karty, c.data_waznosci_karty;

-- =====================================================
-- KROK 3: REJESTRACJA ZWROTU KSIĄŻKI
-- =====================================================

-- Aktualizuj rekord wypożyczenia - ustaw datę rzeczywistego zwrotu i pracownika
UPDATE wypozyczenia 
SET rzeczywista_data_zwrotu = SYSDATE,
    id_pracownika_zwr = 2,
    uwagi = CASE 
        WHEN uwagi IS NULL THEN 'Zwrot zarejestrowany przez system'
        ELSE uwagi || '; Zwrot zarejestrowany przez system'
    END
WHERE nr_karty = 1000001
  AND id_ksiazki = 1
  AND nr_egzemplarza = 1
  AND rzeczywista_data_zwrotu IS NULL;

-- Potwierdzenie wykonania aktualizacji
SELECT 
    CASE 
        WHEN SQL%ROWCOUNT > 0 THEN 'Zwrot książki został zarejestrowany pomyślnie'
        ELSE 'BŁĄD: Nie znaleziono aktywnego wypożyczenia do zwrotu'
    END AS status_operacji
FROM DUAL;

-- =====================================================
-- KROK 4: WERYFIKACJA AUTOMATYCZNEGO NALICZENIA KARY
-- =====================================================

-- Sprawdź czy trigger automatycznie nałożył karę za przetrzymanie
-- (wykonuje się automatycznie dzięki triggerowi trg_kara_za_przetrzymanie)
SELECT 
    k.nr_karty,
    k.data_nalozenia,
    k.kwota_kary,
    k.powod_kary,
    k.status_kary,
    p.imie || ' ' || p.nazwisko AS nalozyl_pracownik
FROM kary k
JOIN pracownicyBiblioteki p ON k.id_pracownika = p.id_pracownika
WHERE k.nr_karty = 1000001
  AND k.data_nalozenia >= SYSDATE - 1/24  -- kary nałożone w ciągu ostatniej godziny
ORDER BY k.data_nalozenia DESC;

-- =====================================================
-- KROK 5: SPRAWDZENIE STATUSU EGZEMPLARZA PO ZWROCIE
-- =====================================================

-- Potwierdź że egzemplarz został oznaczony jako dostępny
SELECT 
    e.id_ksiazki,
    k.tytul,
    e.nr_egzemplarza,
    e.status_dostepnosci,
    e.stan_egzemplarza,
    e.lokalizacja,
    CASE 
        WHEN e.status_dostepnosci = 'dostępny' THEN 'OK - Egzemplarz dostępny do wypożyczenia'
        ELSE 'UWAGA - Status egzemplarza wymaga sprawdzenia'
    END AS status_weryfikacji
FROM egzemplarze e
JOIN ksiazki k ON e.id_ksiazki = k.id_ksiazki
WHERE e.id_ksiazki = 1
  AND e.nr_egzemplarza = 1;

-- =====================================================
-- KROK 6: PODSUMOWANIE TRANSAKCJI ZWROTU
-- =====================================================

-- Wygeneruj podsumowanie całej operacji zwrotu
SELECT 
    'PODSUMOWANIE ZWROTU KSIĄŻKI' AS sekcja,
    w.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    k.tytul AS zwrocona_ksiazka,
    w.data_wypozyczenia,
    w.planowana_data_zwrotu,
    w.rzeczywista_data_zwrotu,
    CASE 
        WHEN w.rzeczywista_data_zwrotu > w.planowana_data_zwrotu THEN
            CEIL(w.rzeczywista_data_zwrotu - w.planowana_data_zwrotu) || ' dni opóźnienia'
        ELSE 'Zwrot w terminie'
    END AS status_terminowosci,
    NVL((SELECT SUM(kar.kwota_kary) 
         FROM kary kar 
         WHERE kar.nr_karty = w.nr_karty 
         AND kar.data_nalozenia >= w.data_wypozyczenia
         AND kar.status_kary = 'niezapłacona'), 0) AS nowa_kara_zl,
    p.imie || ' ' || p.nazwisko AS obslugiwal_pracownik
FROM wypozyczenia w
JOIN czytelnicy c ON w.nr_karty = c.nr_karty
JOIN ksiazki k ON w.id_ksiazki = k.id_ksiazki
JOIN pracownicyBiblioteki p ON w.id_pracownika_zwr = p.id_pracownika
WHERE w.nr_karty = 1000001
  AND w.id_ksiazki = 1
  AND w.nr_egzemplarza = 1
  AND w.rzeczywista_data_zwrotu IS NOT NULL
ORDER BY w.rzeczywista_data_zwrotu DESC
FETCH FIRST 1 ROWS ONLY;

-- =====================================================
-- KROK 7: OPCJONALNE - SPRAWDZENIE KOLEJNYCH REZERWACJI
-- =====================================================

-- Sprawdź czy ktoś czeka na ten egzemplarz (aktywne rezerwacje)
SELECT 
    r.nr_karty,
    c.imie || ' ' || c.nazwisko AS oczekujacy_czytelnik,
    c.telefon,
    c.email,
    r.data_rezerwacji,
    r.data_waznosci_rezerwacji,
    'Powiadom o dostępności' AS akcja_do_wykonania
FROM rezerwacje r
JOIN czytelnicy c ON r.nr_karty = c.nr_karty
WHERE r.id_ksiazki = 1
  AND r.nr_egzemplarza = 1
  AND r.status_rezerwacji = 'aktywna'
  AND r.data_waznosci_rezerwacji >= SYSDATE
ORDER BY r.data_rezerwacji;

-- =====================================================
-- COMMIT TRANSAKCJI
-- =====================================================

-- Zatwierdzenie wszystkich zmian w bazie danych
COMMIT;

-- Komunikat końcowy
SELECT 'Proces zwrotu książki został zakończony pomyślnie!' AS komunikat_koncowy FROM DUAL;

-- ============================================================================================================================================================
-- =====================================================
-- FUNKCJA: PROCES WYPOŻYCZENIA KSIĄŻKI
-- =====================================================
-- Parametry wejściowe (do podstawienia w zapytaniach):
-- @nr_karty_czytelnika = 1000002 (Jan Nowak)
-- @szukany_tytul = 'Lalka' (książka do wypożyczenia)
-- @id_pracownika = 1 (Magdalena Zielińska - obsługuje wypożyczenie)

-- =====================================================
-- KROK 1: WERYFIKACJA UPRAWNIEŃ CZYTELNIKA
-- =====================================================

-- Sprawdź status czytelnika i jego możliwość wypożyczenia
SELECT 
    c.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    c.status_karty,
    c.typ_karty,
    c.data_waznosci_karty,
    CASE 
        WHEN c.data_waznosci_karty < SYSDATE THEN 'KARTA WYGASŁA'
        WHEN c.status_karty != 'aktywna' THEN 'KARTA NIEAKTYWNA'
        ELSE 'OK'
    END AS status_uprawnien,
    
    -- Sprawdzenie aktywnych wypożyczeń
    COUNT(w.nr_karty) AS aktualne_wypozyczenia,
    CASE 
        WHEN c.typ_karty = 'dziecięca' AND COUNT(w.nr_karty) >= 3 THEN 'LIMIT PRZEKROCZONY'
        WHEN c.typ_karty IN ('normalna', 'studencka') AND COUNT(w.nr_karty) >= 5 THEN 'LIMIT PRZEKROCZONY'
        WHEN c.typ_karty = 'senior' AND COUNT(w.nr_karty) >= 7 THEN 'LIMIT PRZEKROCZONY'
        ELSE 'OK'
    END AS status_limitu,
    
    -- Sprawdzenie zadłużeń
    NVL(SUM(k.kwota_kary), 0) AS suma_zaleglosci,
    COUNT(CASE WHEN k.status_kary = 'niezapłacona' THEN 1 END) AS niezaplacone_kary,
    CASE 
        WHEN NVL(SUM(k.kwota_kary), 0) > 50 THEN 'WYSOKIE ZADŁUŻENIE'
        WHEN COUNT(CASE WHEN k.status_kary = 'niezapłacona' THEN 1 END) > 3 THEN 'ZBYT WIELE KAR'
        ELSE 'OK'
    END AS status_finansowy

FROM czytelnicy c
LEFT JOIN wypozyczenia w ON c.nr_karty = w.nr_karty AND w.rzeczywista_data_zwrotu IS NULL
LEFT JOIN kary k ON c.nr_karty = k.nr_karty AND k.status_kary = 'niezapłacona'
WHERE c.nr_karty = 1000002
GROUP BY c.nr_karty, c.imie, c.nazwisko, c.status_karty, c.typ_karty, c.data_waznosci_karty;

-- =====================================================
-- KROK 2: WYSZUKANIE DOSTĘPNYCH EGZEMPLARZY
-- =====================================================

-- Znajdź dostępne egzemplarze poszukiwanej książki
SELECT 
    k.id_ksiazki,
    k.tytul,
    k.podtytul,
    k.isbn,
    e.nr_egzemplarza,
    e.stan_egzemplarza,
    e.lokalizacja,
    e.status_dostepnosci,
    
    -- Informacja o autorach
    LISTAGG(a.imie || ' ' || a.nazwisko, ', ') 
        WITHIN GROUP (ORDER BY ka.rola_autora, a.nazwisko) AS autorzy,
    
    -- Sprawdzenie rezerwacji
    CASE 
        WHEN EXISTS (
            SELECT 1 FROM rezerwacje r 
            WHERE r.id_ksiazki = k.id_ksiazki 
            AND r.nr_egzemplarza = e.nr_egzemplarza 
            AND r.status_rezerwacji = 'aktywna'
            AND r.nr_karty = 1000002
        ) THEN 'ZAREZERWOWANE PRZEZ CIEBIE'
        WHEN EXISTS (
            SELECT 1 FROM rezerwacje r 
            WHERE r.id_ksiazki = k.id_ksiazki 
            AND r.nr_egzemplarza = e.nr_egzemplarza 
            AND r.status_rezerwacji = 'aktywna'
        ) THEN 'ZAREZERWOWANE PRZEZ INNEGO'
        ELSE 'BRAK REZERWACJI'
    END AS status_rezerwacji,
    
    -- Priorytet wypożyczenia
    CASE 
        WHEN e.status_dostepnosci = 'dostępny' AND e.stan_egzemplarza IN ('nowy', 'dobry') THEN 1
        WHEN e.status_dostepnosci = 'dostępny' THEN 2
        ELSE 3
    END AS priorytet_wyboru

FROM ksiazki k
JOIN egzemplarze e ON k.id_ksiazki = e.id_ksiazki
LEFT JOIN ksiazka_autor ka ON k.id_ksiazki = ka.id_ksiazki
LEFT JOIN autorzy a ON ka.id_autora = a.id_autora
WHERE UPPER(k.tytul) LIKE '%' || UPPER('Lalka') || '%'
  AND e.status_dostepnosci IN ('dostępny', 'zarezerwowany')
GROUP BY k.id_ksiazki, k.tytul, k.podtytul, k.isbn, 
         e.nr_egzemplarza, e.stan_egzemplarza, e.lokalizacja, e.status_dostepnosci
ORDER BY priorytet_wyboru, k.tytul, e.nr_egzemplarza;

-- =====================================================
-- KROK 3: SPRAWDZENIE HISTORII WYPOŻYCZEŃ KSIĄŻKI
-- =====================================================

-- Sprawdź historię wypożyczeń wybranego egzemplarza
SELECT 
    w.data_wypozyczenia,
    w.planowana_data_zwrotu,
    w.rzeczywista_data_zwrotu,
    c.imie || ' ' || c.nazwisko AS poprzedni_czytelnik,
    w.przedluzenia,
    w.uwagi,
    CASE 
        WHEN w.rzeczywista_data_zwrotu > w.planowana_data_zwrotu THEN 
            'Zwrócono z opóźnieniem (' || (w.rzeczywista_data_zwrotu - w.planowana_data_zwrotu) || ' dni)'
        WHEN w.rzeczywista_data_zwrotu IS NULL THEN 'AKTUALNIE WYPOŻYCZONE'
        ELSE 'Zwrócono w terminie'
    END AS status_historyczny

FROM wypozyczenia w
JOIN czytelnicy c ON w.nr_karty = c.nr_karty
WHERE w.id_ksiazki = 3  -- ID książki "Lalka"
  AND w.nr_egzemplarza = 1
ORDER BY w.data_wypozyczenia DESC
FETCH FIRST 5 ROWS ONLY;

-- =====================================================
-- KROK 4: REALIZACJA WYPOŻYCZENIA
-- =====================================================

-- Wstaw nowy rekord wypożyczenia
INSERT INTO wypozyczenia (
    nr_karty,
    id_ksiazki,
    nr_egzemplarza,
    data_wypozyczenia,
    planowana_data_zwrotu,
    rzeczywista_data_zwrotu,
    id_pracownika_wyp,
    id_pracownika_zwr,
    przedluzenia,
    uwagi
) VALUES (
    1000002,  -- Jan Nowak
    3,        -- Lalka
    1,        -- egzemplarz nr 1
    SYSDATE,
    SYSDATE + 14,  -- 14 dni na zwrot
    NULL,
    1,        -- Magdalena Zielińska
    NULL,
    0,
    'Wypożyczenie standardowe'
);

-- Potwierdzenie wykonania wypożyczenia
SELECT 
    CASE 
        WHEN SQL%ROWCOUNT > 0 THEN 'Wypożyczenie zostało zarejestrowane pomyślnie'
        ELSE 'BŁĄD: Nie udało się zarejestrować wypożyczenia'
    END AS status_wypozyczenia,
    SYSDATE AS data_operacji
FROM DUAL;

-- =====================================================
-- KROK 5: AKTUALIZACJA STATUSU EGZEMPLARZA
-- =====================================================
-- (Ten krok jest wykonywany automatycznie przez trigger trg_wypozyczenie_dostepnosc)

-- Sprawdź czy status egzemplarza został poprawnie zaktualizowany
SELECT 
    e.id_ksiazki,
    k.tytul,
    e.nr_egzemplarza,
    e.status_dostepnosci,
    CASE 
        WHEN e.status_dostepnosci = 'wypożyczony' THEN 'OK - Status poprawnie zaktualizowany'
        ELSE 'UWAGA - Status wymaga sprawdzenia'
    END AS weryfikacja_statusu
FROM egzemplarze e
JOIN ksiazki k ON e.id_ksiazki = k.id_ksiazki
WHERE e.id_ksiazki = 3
  AND e.nr_egzemplarza = 1;

-- =====================================================
-- KROK 6: ANULOWANIE REZERWACJI (JEŚLI ISTNIAŁA)
-- =====================================================
-- (Ten krok jest wykonywany automatycznie przez trigger trg_wypozyczenie_dostepnosc)

-- Sprawdź czy rezerwacja została poprawnie zrealizowana
SELECT 
    r.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    r.data_rezerwacji,
    r.status_rezerwacji,
    CASE 
        WHEN r.status_rezerwacji = 'zrealizowana' THEN 'OK - Rezerwacja zrealizowana'
        ELSE 'INFO - Brak wcześniejszej rezerwacji'
    END AS status_rezerwacji
FROM rezerwacje r
JOIN czytelnicy c ON r.nr_karty = c.nr_karty
WHERE r.id_ksiazki = 3
  AND r.nr_egzemplarza = 1
  AND r.nr_karty = 1000002
ORDER BY r.data_rezerwacji DESC
FETCH FIRST 1 ROWS ONLY;

-- =====================================================
-- KROK 7: GENEROWANIE POTWIERDZENIA WYPOŻYCZENIA
-- =====================================================

-- Wygeneruj szczegółowe potwierdzenie wypożyczenia
SELECT 
    'POTWIERDZENIE WYPOŻYCZENIA' AS dokument,
    w.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    c.telefon,
    c.email,
    k.tytul AS wypozyczona_ksiazka,
    LISTAGG(a.imie || ' ' || a.nazwisko, ', ') 
        WITHIN GROUP (ORDER BY a.nazwisko) AS autorzy,
    k.isbn,
    w.nr_egzemplarza,
    w.data_wypozyczenia,
    w.planowana_data_zwrotu,
    (w.planowana_data_zwrotu - w.data_wypozyczenia) AS okres_wypozyczenia_dni,
    e.lokalizacja AS lokalizacja_egzemplarza,
    p.imie || ' ' || p.nazwisko AS obslugiwal_pracownik,
    
    -- Instrukcje dla czytelnika
    CASE c.typ_karty
        WHEN 'dziecięca' THEN 'Przypominamy o konieczności zwrotu w terminie. Maksymalnie 3 książki jednocześnie.'
        WHEN 'studencka' THEN 'Możliwość przedłużenia o 7 dni. Maksymalnie 5 książek jednocześnie.'
        WHEN 'senior' THEN 'Możliwość przedłużenia o 14 dni. Maksymalnie 7 książek jednocześnie.'
        ELSE 'Możliwość przedłużenia o 7 dni. Maksymalnie 5 książek jednocześnie.'
    END AS instrukcje

FROM wypozyczenia w
JOIN czytelnicy c ON w.nr_karty = c.nr_karty
JOIN ksiazki k ON w.id_ksiazki = k.id_ksiazki
JOIN egzemplarze e ON w.id_ksiazki = e.id_ksiazki AND w.nr_egzemplarza = e.nr_egzemplarza
JOIN pracownicyBiblioteki p ON w.id_pracownika_wyp = p.id_pracownika
LEFT JOIN ksiazka_autor ka ON k.id_ksiazki = ka.id_ksiazki
LEFT JOIN autorzy a ON ka.id_autora = a.id_autora
WHERE w.nr_karty = 1000002
  AND w.id_ksiazki = 3
  AND w.nr_egzemplarza = 1
  AND w.rzeczywista_data_zwrotu IS NULL
GROUP BY w.nr_karty, c.imie, c.nazwisko, c.telefon, c.email, c.typ_karty,
         k.tytul, k.isbn, w.nr_egzemplarza, w.data_wypozyczenia, 
         w.planowana_data_zwrotu, e.lokalizacja, p.imie, p.nazwisko;

-- =====================================================
-- KROK 8: AKTUALIZACJA STATYSTYK CZYTELNIKA
-- =====================================================

-- Sprawdź zaktualizowane statystyki czytelnika po wypożyczeniu
SELECT 
    c.nr_karty,
    c.imie || ' ' || c.nazwisko AS czytelnik,
    COUNT(w.nr_karty) AS wszystkie_wypozyczenia,
    COUNT(CASE WHEN w.rzeczywista_data_zwrotu IS NULL THEN 1 END) AS aktywne_wypozyczenia,
    COUNT(CASE WHEN w.rzeczywista_data_zwrotu IS NOT NULL THEN 1 END) AS zwrocone_wypozyczenia,
    ROUND(AVG(CASE 
        WHEN w.rzeczywista_data_zwrotu IS NOT NULL 
        THEN w.rzeczywista_data_zwrotu - w.data_wypozyczenia 
    END), 1) AS sredni_czas_przetrzymania_dni,
    
    -- Najbliższy termin zwrotu
    MIN(CASE WHEN w.rzeczywista_data_zwrotu IS NULL THEN w.planowana_data_zwrotu END) AS najblizszy_zwrot
    
FROM czytelnicy c
LEFT JOIN wypozyczenia w ON c.nr_karty = w.nr_karty
WHERE c.nr_karty = 1000002
GROUP BY c.nr_karty, c.imie, c.nazwisko;

-- =====================================================
-- KROK 9: OPCJONALNE - POWIADOMIENIA I PRZYPOMNIENIA
-- =====================================================

-- Sprawdź czy czytelnik ma inne książki do oddania wkrótce
SELECT 
    k.tytul,
    w.nr_egzemplarza,
    w.planowana_data_zwrotu,
    CASE 
        WHEN w.planowana_data_zwrotu < SYSDATE THEN 'PRZETERMINOWANE!'
        WHEN w.planowana_data_zwrotu - SYSDATE <= 3 THEN 'PRZYPOMNIENIE - zostały ' || 
            CEIL(w.planowana_data_zwrotu - SYSDATE) || ' dni'
        ELSE 'OK - ' || CEIL(w.planowana_data_zwrotu - SYSDATE) || ' dni do zwrotu'
    END AS status_terminu
FROM wypozyczenia w
JOIN ksiazki k ON w.id_ksiazki = k.id_ksiazki
WHERE w.nr_karty = 1000002
  AND w.rzeczywista_data_zwrotu IS NULL
ORDER BY w.planowana_data_zwrotu;

-- =====================================================
-- COMMIT TRANSAKCJI
-- =====================================================

-- Zatwierdzenie wszystkich zmian w bazie danych
COMMIT;

-- Komunikat końcowy z podsumowaniem
SELECT 
    'Proces wypożyczenia został zakończony pomyślnie!' AS komunikat,
    TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS czas_zakonczenia,
    'Książka "Lalka" wypożyczona do ' || TO_CHAR(SYSDATE + 14, 'YYYY-MM-DD') AS termin_zwrotu
FROM DUAL;