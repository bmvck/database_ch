--------------------------------------------------------------------------------
-- Schema: Contábil/Financeiro (Oracle)
-- Versão corrigida – evita ORA-00942 nos DROPS e remove duplicidade de colunas.
-- Observações:
-- 1) Os DROPS são "seguros": ignoram o erro -942 (objeto inexistente).
-- 2) A ordem de DROP respeita dependências (filhas -> pais).
-- 3) REG_CONT não possui mais a coluna duplicada (id_registro_contabil).
-- 4) Regras de dados úteis: UNIQUE em CPF/CNPJ e E-MAIL; CHECKs simples.
-- 5) Índices nas FKs e trigger para data_atualizacao.
--------------------------------------------------------------------------------

---------------------------
-- DROPS SEGUROS (FILHAS)
---------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE VENDAS CASCADE CONSTRAINTS'; 
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE REG_CONT CASCADE CONSTRAINTS'; 
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE CONTA CASCADE CONSTRAINTS'; 
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE CLIENTE CASCADE CONSTRAINTS'; 
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

BEGIN EXECUTE IMMEDIATE 'DROP TABLE CENTRO_CUSTO CASCADE CONSTRAINTS'; 
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

---------------------------
-- SEQUENCES
---------------------------
CREATE SEQUENCE CLIENTE_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE CENTRO_CUSTO_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE CONTA_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE REG_CONT_SEQ START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE VENDAS_SEQ START WITH 1 INCREMENT BY 1;

---------------------------
-- TABELAS (PAIS -> FILHAS)
---------------------------

-- CENTRO_CUSTO
CREATE TABLE CENTRO_CUSTO
(
  id_centro_custo   NUMBER(4)     NOT NULL,
  nome_centro_custo VARCHAR2(70)  NOT NULL
);
ALTER TABLE CENTRO_CUSTO
  ADD CONSTRAINT CENTRO_CUSTO_PK PRIMARY KEY (id_centro_custo);


-- CLIENTE
CREATE TABLE CLIENTE
(
  id_cliente    NUMBER(5)       NOT NULL,
  nome_cliente  VARCHAR2(100)   NOT NULL,
  data_cadastro DATE            DEFAULT SYSDATE NOT NULL,
  cpf_cnpj      VARCHAR2(14)    NOT NULL,
  email         VARCHAR2(100)   NOT NULL,
  senha         VARCHAR2(100)   NOT NULL,
  ativo         CHAR(1)         DEFAULT 'S' NOT NULL
);
ALTER TABLE CLIENTE
  ADD CONSTRAINT CLIENTE_PK PRIMARY KEY (id_cliente);

-- Regras de integridade adicionais
ALTER TABLE CLIENTE
  ADD CONSTRAINT CLIENTE_UQ_CPF_CNPJ UNIQUE (cpf_cnpj);
ALTER TABLE CLIENTE
  ADD CONSTRAINT CLIENTE_UQ_EMAIL UNIQUE (email);
ALTER TABLE CLIENTE
  ADD CONSTRAINT CLIENTE_CHK_ATIVO CHECK (ativo IN ('S','N'));


-- CONTA
CREATE TABLE CONTA
(
  id_conta           NUMBER(4)     NOT NULL,
  nome_conta         VARCHAR2(70)  NOT NULL,
  tipo               CHAR(1)       NOT NULL,  -- Ex.: 'R' (receita), 'D' (despesa)
  CLIENTE_id_cliente NUMBER(5)     -- opcional: conta pode ser genérica
);
ALTER TABLE CONTA
  ADD CONSTRAINT CONTA_PK PRIMARY KEY (id_conta);

ALTER TABLE CONTA
  ADD CONSTRAINT CONTA_CHK_TIPO CHECK (tipo IN ('R','D'));


-- REG_CONT (lançamentos contábeis)
CREATE TABLE REG_CONT
(
  id_reg_cont                  NUMBER(4)     NOT NULL,
  valor                        NUMBER(9,2)   NOT NULL,
  CONTA_id_conta               NUMBER(4)     NOT NULL,
  CENTRO_CUSTO_id_centro_custo NUMBER(4)     NOT NULL,
  data_criacao                 DATE          DEFAULT SYSDATE,
  data_atualizacao             DATE
);
ALTER TABLE REG_CONT
  ADD CONSTRAINT REGIST_CONTABIL_PK PRIMARY KEY (id_reg_cont);


-- VENDAS
CREATE TABLE VENDAS
(
  id_vendas            NUMBER(9)   NOT NULL,
  CLIENTE_id_cliente   NUMBER(5)   NOT NULL,
  REG_CONT_id_reg_cont NUMBER(4)   NOT NULL
);
ALTER TABLE VENDAS
  ADD CONSTRAINT VENDAS_PK PRIMARY KEY (id_vendas);


---------------------------
-- RELACIONAMENTOS (FKs)
---------------------------

ALTER TABLE CONTA
  ADD CONSTRAINT CONTA_CLIENTE_FK FOREIGN KEY (CLIENTE_id_cliente)
  REFERENCES CLIENTE (id_cliente);

ALTER TABLE REG_CONT
  ADD CONSTRAINT REG_CONT_CONTA_FK FOREIGN KEY (CONTA_id_conta)
  REFERENCES CONTA (id_conta);

ALTER TABLE REG_CONT
  ADD CONSTRAINT REG_CONT_CENTRO_CUSTO_FK FOREIGN KEY (CENTRO_CUSTO_id_centro_custo)
  REFERENCES CENTRO_CUSTO (id_centro_custo);

ALTER TABLE VENDAS
  ADD CONSTRAINT VENDAS_CLIENTE_FK FOREIGN KEY (CLIENTE_id_cliente)
  REFERENCES CLIENTE (id_cliente);

ALTER TABLE VENDAS
  ADD CONSTRAINT VENDAS_REG_CONT_FK FOREIGN KEY (REG_CONT_id_reg_cont)
  REFERENCES REG_CONT (id_reg_cont);


---------------------------
-- ÍNDICES ÚTEIS
---------------------------
CREATE INDEX IX_CONTA_CLIENTE      ON CONTA   (CLIENTE_id_cliente);
CREATE INDEX IX_REG_CONT_CONTA     ON REG_CONT(CONTA_id_conta);
CREATE INDEX IX_REG_CONT_CCUSTO    ON REG_CONT(CENTRO_CUSTO_id_centro_custo);
CREATE INDEX IX_VENDAS_CLIENTE     ON VENDAS  (CLIENTE_id_cliente);
CREATE INDEX IX_VENDAS_REG_CONT    ON VENDAS  (REG_CONT_id_reg_cont);


---------------------------
-- TRIGGER DE AUDITORIA
---------------------------
CREATE OR REPLACE TRIGGER TRG_REG_CONT_BIU_AUD
BEFORE INSERT OR UPDATE ON REG_CONT
FOR EACH ROW
BEGIN
  IF INSERTING THEN
    IF :NEW.data_criacao IS NULL THEN
      :NEW.data_criacao := SYSDATE;
    END IF;
  END IF;

  IF UPDATING THEN
    :NEW.data_atualizacao := SYSDATE;
  END IF;
END;
/

-- FIM
