-- =====================================================================
-- BLOC-NOTES INTELLIGENT — Schéma physique (PostgreSQL 14+)
-- Dérivé du MCD : Utilisateur / Compte / Operation / Categorie /
-- Budget / Objectif / Abonnement / Alerte / AnalyseComportementale
-- =====================================================================
-- Hypothèse : moteur PostgreSQL (types UUID, ENUM, gen_random_uuid()).
-- Pour MySQL/MariaDB : remplacer UUID par CHAR(36), gen_random_uuid()
-- par (UUID()), et les types ENUM par des ENUM('a','b',...) inline.
-- =====================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ---------------------------------------------------------------------
-- Types énumérés
-- ---------------------------------------------------------------------
CREATE TYPE type_compte           AS ENUM ('courant', 'epargne', 'mobile_money');
CREATE TYPE devise_compte         AS ENUM ('CDF', 'USD');
CREATE TYPE type_operation        AS ENUM ('depense', 'recette');
CREATE TYPE type_categorie        AS ENUM ('depense', 'recette');
CREATE TYPE frequence_abonnement  AS ENUM ('hebdomadaire', 'mensuelle', 'annuelle');
CREATE TYPE statut_abonnement     AS ENUM ('actif', 'en_pause', 'resilie');
CREATE TYPE periode_budget        AS ENUM ('hebdomadaire', 'mensuelle', 'annuelle');
CREATE TYPE type_alerte           AS ENUM ('depassement_budget', 'anomalie', 'fuite_financiere', 'objectif');
CREATE TYPE statut_alerte         AS ENUM ('nouvelle', 'lue', 'traitee');

-- ---------------------------------------------------------------------
-- Fonction utilitaire : mise à jour automatique de updated_at
-- ---------------------------------------------------------------------
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ---------------------------------------------------------------------
-- UTILISATEUR
-- ---------------------------------------------------------------------
CREATE TABLE utilisateur (
  id_utilisateur  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom             VARCHAR(150) NOT NULL,
  email           VARCHAR(255) NOT NULL UNIQUE,
  mot_de_passe    VARCHAR(255) NOT NULL,
  date_creation   TIMESTAMP NOT NULL DEFAULT now(),
  created_at      TIMESTAMP NOT NULL DEFAULT now(),
  updated_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_utilisateur_updated_at
  BEFORE UPDATE ON utilisateur
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- CATEGORIE (référentiel, indépendant de l'utilisateur)
-- ---------------------------------------------------------------------
CREATE TABLE categorie (
  id_categorie  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom           VARCHAR(100) NOT NULL,
  type          type_categorie NOT NULL,
  created_at    TIMESTAMP NOT NULL DEFAULT now(),
  updated_at    TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (nom, type)
);
CREATE TRIGGER trg_categorie_updated_at
  BEFORE UPDATE ON categorie
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- ABONNEMENT (charges récurrentes détectées par le Tracker IA)
-- ---------------------------------------------------------------------
CREATE TABLE abonnement (
  id_abonnement  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nom            VARCHAR(150) NOT NULL,
  montant        NUMERIC(14,2) NOT NULL CHECK (montant >= 0),
  frequence      frequence_abonnement NOT NULL,
  statut         statut_abonnement NOT NULL DEFAULT 'actif',
  created_at     TIMESTAMP NOT NULL DEFAULT now(),
  updated_at     TIMESTAMP NOT NULL DEFAULT now()
);
CREATE TRIGGER trg_abonnement_updated_at
  BEFORE UPDATE ON abonnement
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- COMPTE (1 utilisateur -> 0..n comptes)
-- ---------------------------------------------------------------------
CREATE TABLE compte (
  id_compte       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur  UUID NOT NULL REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE,
  type            type_compte NOT NULL,
  devise          devise_compte NOT NULL,
  solde           NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at      TIMESTAMP NOT NULL DEFAULT now(),
  updated_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_compte_utilisateur ON compte(id_utilisateur);
CREATE TRIGGER trg_compte_updated_at
  BEFORE UPDATE ON compte
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- OPERATION (1 compte -> 0..n operations ; 1 categorie -> 0..n ;
--            0..1 abonnement -> 0..n operations)
-- ---------------------------------------------------------------------
CREATE TABLE operation (
  id_operation      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_compte         UUID NOT NULL REFERENCES compte(id_compte) ON DELETE CASCADE,
  id_categorie      UUID NOT NULL REFERENCES categorie(id_categorie) ON DELETE RESTRICT,
  id_abonnement     UUID REFERENCES abonnement(id_abonnement) ON DELETE SET NULL,
  montant           NUMERIC(14,2) NOT NULL CHECK (montant > 0),
  date_operation    DATE NOT NULL,
  type              type_operation NOT NULL,
  description       VARCHAR(255),
  verifiee_par_ia   BOOLEAN NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMP NOT NULL DEFAULT now(),
  updated_at        TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_operation_compte      ON operation(id_compte);
CREATE INDEX idx_operation_categorie   ON operation(id_categorie);
CREATE INDEX idx_operation_abonnement  ON operation(id_abonnement);
CREATE INDEX idx_operation_date        ON operation(date_operation);
CREATE TRIGGER trg_operation_updated_at
  BEFORE UPDATE ON operation
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- BUDGET (1 utilisateur -> 0..n ; 1 categorie -> 0..n)
-- ---------------------------------------------------------------------
CREATE TABLE budget (
  id_budget       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur  UUID NOT NULL REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE,
  id_categorie    UUID NOT NULL REFERENCES categorie(id_categorie) ON DELETE CASCADE,
  montant_alloue  NUMERIC(14,2) NOT NULL CHECK (montant_alloue >= 0),
  periode         periode_budget NOT NULL,
  created_at      TIMESTAMP NOT NULL DEFAULT now(),
  updated_at      TIMESTAMP NOT NULL DEFAULT now(),
  UNIQUE (id_utilisateur, id_categorie, periode)
);
CREATE INDEX idx_budget_utilisateur ON budget(id_utilisateur);
CREATE TRIGGER trg_budget_updated_at
  BEFORE UPDATE ON budget
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- OBJECTIF (1 utilisateur -> 0..n)
-- ---------------------------------------------------------------------
CREATE TABLE objectif (
  id_objectif     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur  UUID NOT NULL REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE,
  nom             VARCHAR(150) NOT NULL,
  montant_cible   NUMERIC(14,2) NOT NULL CHECK (montant_cible > 0),
  montant_actuel  NUMERIC(14,2) NOT NULL DEFAULT 0 CHECK (montant_actuel >= 0),
  date_echeance   DATE,
  created_at      TIMESTAMP NOT NULL DEFAULT now(),
  updated_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_objectif_utilisateur ON objectif(id_utilisateur);
CREATE TRIGGER trg_objectif_updated_at
  BEFORE UPDATE ON objectif
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ---------------------------------------------------------------------
-- ALERTE (générée par le Tracker IA, 1 utilisateur -> 0..n)
-- ---------------------------------------------------------------------
CREATE TABLE alerte (
  id_alerte       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur  UUID NOT NULL REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE,
  type            type_alerte NOT NULL,
  message         VARCHAR(255) NOT NULL,
  date_emission   TIMESTAMP NOT NULL DEFAULT now(),
  statut          statut_alerte NOT NULL DEFAULT 'nouvelle',
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_alerte_utilisateur ON alerte(id_utilisateur);
CREATE INDEX idx_alerte_statut      ON alerte(statut);

-- ---------------------------------------------------------------------
-- ANALYSE_COMPORTEMENTALE (générée par le Tracker IA, 1 utilisateur -> 0..n)
-- ---------------------------------------------------------------------
CREATE TABLE analyse_comportementale (
  id_analyse      UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  id_utilisateur  UUID NOT NULL REFERENCES utilisateur(id_utilisateur) ON DELETE CASCADE,
  periode         VARCHAR(50) NOT NULL,
  tendance        VARCHAR(100) NOT NULL,
  score           NUMERIC(5,2),
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);
CREATE INDEX idx_analyse_utilisateur ON analyse_comportementale(id_utilisateur);

-- =====================================================================
-- Fin du script
-- =====================================================================
