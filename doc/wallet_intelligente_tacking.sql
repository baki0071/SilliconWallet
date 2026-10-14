-- =====================================================================
-- Script PostgreSQL : création du schéma (issu du MCD / MLRD)
-- Ordre de création : tables référencées d'abord, puis tables
-- dépendantes, puis tables d'association N-N.
-- =====================================================================

BEGIN;

-- ---------------------------------------------------------------------
-- Nettoyage (ordre inverse des dépendances) : utile en développement
-- ---------------------------------------------------------------------
DROP TABLE IF EXISTS accepter      CASCADE;
DROP TABLE IF EXISTS proposer      CASCADE;
DROP TABLE IF EXISTS reequilibrer  CASCADE;
DROP TABLE IF EXISTS actionner     CASCADE;
DROP TABLE IF EXISTS posseder      CASCADE;
DROP TABLE IF EXISTS patrimoine    CASCADE;
DROP TABLE IF EXISTS evenement     CASCADE;
DROP TABLE IF EXISTS plan          CASCADE;
DROP TABLE IF EXISTS role          CASCADE;
DROP TABLE IF EXISTS utilisateur   CASCADE;
DROP TABLE IF EXISTS agent         CASCADE;

-- =====================================================================
-- 1. TABLES D'ENTITÉS
-- =====================================================================

-- AGENT : entité qui analyse les événements et propose des plans
CREATE TABLE agent (
    id_agent     INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom          VARCHAR(100) NOT NULL,
    type         VARCHAR(50)  NOT NULL,
    description  TEXT
);

-- UTILISATEUR : "USER" du MLRD, renommée car USER est un mot réservé
-- en PostgreSQL (évite d'avoir à le mettre entre guillemets partout).
CREATE TABLE utilisateur (
    id_user           INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom               VARCHAR(100) NOT NULL,
    prenom            VARCHAR(100) NOT NULL,
    email             VARCHAR(255) NOT NULL UNIQUE,   -- unicité prévue au MLRD
    date_inscription  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ROLE
CREATE TABLE role (
    id_role      INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom          VARCHAR(100) NOT NULL UNIQUE,
    description  TEXT
);

-- PLAN
CREATE TABLE plan (
    id_plan        INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom            VARCHAR(150) NOT NULL,
    description    TEXT,
    date_creation  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    statut         VARCHAR(50)  NOT NULL
);

-- =====================================================================
-- 2. TABLES AVEC CLÉ ÉTRANGÈRE MIGRÉE (associations 1-N)
-- =====================================================================

-- EVENEMENT
-- Association "analyser" : un événement est analysé par UN seul agent,
-- un agent peut analyser plusieurs événements -> FK id_agent ici.
CREATE TABLE evenement (
    id_evenement    INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    date_evenement  TIMESTAMP    NOT NULL,
    type            VARCHAR(50)  NOT NULL,
    description     TEXT,
    statut          VARCHAR(50)  NOT NULL,
    id_agent        INTEGER      NOT NULL,
    CONSTRAINT fk_evenement_agent
        FOREIGN KEY (id_agent) REFERENCES agent (id_agent)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- PATRIMOINE
-- Association "fournir" (1,1) côté PATRIMOINE : un patrimoine est lié à
-- UN seul événement -> FK id_evenement ici (NOT NULL).
CREATE TABLE patrimoine (
    id_patrimoine  INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    nom            VARCHAR(150) NOT NULL,
    description    TEXT,
    localisation   VARCHAR(255),
    type           VARCHAR(50)  NOT NULL,
    id_evenement   INTEGER      NOT NULL,
    CONSTRAINT fk_patrimoine_evenement
        FOREIGN KEY (id_evenement) REFERENCES evenement (id_evenement)
        ON UPDATE CASCADE ON DELETE RESTRICT
);

-- =====================================================================
-- 3. TABLES D'ASSOCIATION (associations N-N)
-- PK composée = concaténation des deux identifiants.
-- ON DELETE CASCADE : supprimer un côté supprime les liaisons.
-- =====================================================================

-- POSSEDER : un utilisateur peut avoir plusieurs rôles et inversement
CREATE TABLE posseder (
    id_user  INTEGER NOT NULL,
    id_role  INTEGER NOT NULL,
    PRIMARY KEY (id_user, id_role),
    CONSTRAINT fk_posseder_user
        FOREIGN KEY (id_user) REFERENCES utilisateur (id_user)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_posseder_role
        FOREIGN KEY (id_role) REFERENCES role (id_role)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ACTIONNER : quel utilisateur déclenche quel événement
CREATE TABLE actionner (
    id_user       INTEGER NOT NULL,
    id_evenement  INTEGER NOT NULL,
    PRIMARY KEY (id_user, id_evenement),
    CONSTRAINT fk_actionner_user
        FOREIGN KEY (id_user) REFERENCES utilisateur (id_user)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_actionner_evenement
        FOREIGN KEY (id_evenement) REFERENCES evenement (id_evenement)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- REEQUILIBRER : un événement peut mener à plusieurs plans
-- et un plan peut servir plusieurs événements
CREATE TABLE reequilibrer (
    id_evenement  INTEGER NOT NULL,
    id_plan       INTEGER NOT NULL,
    PRIMARY KEY (id_evenement, id_plan),
    CONSTRAINT fk_reequilibrer_evenement
        FOREIGN KEY (id_evenement) REFERENCES evenement (id_evenement)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_reequilibrer_plan
        FOREIGN KEY (id_plan) REFERENCES plan (id_plan)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- PROPOSER : quel agent propose quel plan
-- (si un plan n'a qu'un seul agent, supprimer cette table et ajouter
--  id_agent NOT NULL dans PLAN)
CREATE TABLE proposer (
    id_agent  INTEGER NOT NULL,
    id_plan   INTEGER NOT NULL,
    PRIMARY KEY (id_agent, id_plan),
    CONSTRAINT fk_proposer_agent
        FOREIGN KEY (id_agent) REFERENCES agent (id_agent)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_proposer_plan
        FOREIGN KEY (id_plan) REFERENCES plan (id_plan)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- ACCEPTER : quel utilisateur valide quel plan
CREATE TABLE accepter (
    id_user  INTEGER NOT NULL,
    id_plan  INTEGER NOT NULL,
    PRIMARY KEY (id_user, id_plan),
    CONSTRAINT fk_accepter_user
        FOREIGN KEY (id_user) REFERENCES utilisateur (id_user)
        ON UPDATE CASCADE ON DELETE CASCADE,
    CONSTRAINT fk_accepter_plan
        FOREIGN KEY (id_plan) REFERENCES plan (id_plan)
        ON UPDATE CASCADE ON DELETE CASCADE
);

-- =====================================================================
-- 4. INDEX SUR LES CLÉS ÉTRANGÈRES
-- PostgreSQL n'indexe pas automatiquement les FK. Les premières
-- colonnes des PK composées sont déjà couvertes : on indexe donc la
-- 2e colonne (sens inverse de recherche) et les FK des tables 1-N.
-- =====================================================================
CREATE INDEX idx_evenement_agent       ON evenement   (id_agent);
CREATE INDEX idx_patrimoine_evenement  ON patrimoine  (id_evenement);
CREATE INDEX idx_posseder_role         ON posseder    (id_role);
CREATE INDEX idx_actionner_evenement   ON actionner   (id_evenement);
CREATE INDEX idx_reequilibrer_plan     ON reequilibrer (id_plan);
CREATE INDEX idx_proposer_plan         ON proposer    (id_plan);
CREATE INDEX idx_accepter_plan         ON accepter    (id_plan);

COMMIT;
