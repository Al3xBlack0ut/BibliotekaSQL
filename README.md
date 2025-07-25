# System Zarządzania Biblioteką
## Autor: Aleks Czarnecki

Ten projekt zawiera kompletny skrypt SQL do utworzenia i obsługi systemu zarządzania biblioteką w bazie danych Oracle. Skrypt definiuje strukturę bazy, relacje, mechanizmy integralności oraz przykładowe dane.

## Zawartość
- **Tworzenie i usuwanie tabel oraz sekwencji**
- **Definicje tabel**: czytelnicy, autorzy, książki, pracownicy, egzemplarze, wypożyczenia, rezerwacje, kary
- **Relacje i klucze obce**
- **Triggery**: automatyzacja operacji (np. naliczanie kar, aktualizacja statusów)
- **Widoki**: statystyki, dostępność, aktywne wypożyczenia
- **Przykładowe dane**: wstawianie czytelników, pracowników, autorów, książek, egzemplarzy, wypożyczeń, rezerwacji
- **Przykładowe operacje**: proces zwrotu i wypożyczenia książki krok po kroku

## Wymagania
- Oracle Database (zalecana wersja 12c lub nowsza)
- Uprawnienia do tworzenia tabel, sekwencji, widoków, triggerów

## Instalacja
1. Otwórz narzędzie SQL (np. SQL*Plus, Oracle SQL Developer)
2. Połącz się z odpowiednią bazą danych
3. Uruchom cały skrypt `biblioteka.sql`

## Funkcjonalności
- Rejestracja czytelników, pracowników, autorów, książek
- Obsługa wypożyczeń, rezerwacji, zwrotów
- Automatyczne naliczanie kar za przetrzymanie
- Statystyki czytelników i wypożyczeń
- Widoki ułatwiające raportowanie i analizę

## Przykładowe operacje
- Wypożyczenie książki: sprawdzenie uprawnień, dostępności, rejestracja wypożyczenia
- Zwrot książki: aktualizacja statusu, naliczenie kary, podsumowanie operacji
