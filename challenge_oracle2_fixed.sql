--------------------------------------------------------------------------------
-- FIX: Modelo Único (Contábil + IoT) alinhado aos nomes de tabela/colunas do seu script atual
-- Ajustes principais:
--  - Usa CONTA_CONTABIL (e não CONTA)
--  - Usa nomes de colunas compostos em VENDA_EVENTO (ex.: servico_id_servico, cliente_id_cliente, dispositivo_iot_id_dispositivo)
--  - Procedure PR_SETUP_DEFAULTS corrigida para CONTA_CONTABIL
--  - Trigger TRG_VENDA_EVENTO_AI ajustada para colunas corretas
--  - Trigger TRG_VENDAS_AI_ENSURE_REGCONT mantida (fallback)
--  - Drops protegidos com EXECUTE IMMEDIATE (não falham se tabela/sequence não existir)
--------------------------------------------------------------------------------

---------------------------
-- DROPS SEGUROS (FILHAS)
---------------------------
BEGIN EXECUTE IMMEDIATE 'DROP TABLE venda_evento CASCADE CONSTRAINTS';     EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE vendas CASCADE CONSTRAINTS';           EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE reg_cont CASCADE CONSTRAINTS';         EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE servico CASCADE CONSTRAINTS';          EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE dispositivo_iot CASCADE CONSTRAINTS';  EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE conta_contabil CASCADE CONSTRAINTS';   EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE cliente CASCADE CONSTRAINTS';          EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE centro_custo CASCADE CONSTRAINTS';     EXCEPTION WHEN OTHERS THEN IF SQLCODE != -942 THEN RAISE; END IF; END;
/

---------------------------
-- DROP SEQUENCES (SE EXISTIREM)
---------------------------
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE vendas_seq';           EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE reg_cont_seq';         EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE conta_seq';            EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE cliente_seq';          EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE centro_custo_seq';     EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_dispositivo_iot';  EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_servico';          EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE seq_venda_evento';     EXCEPTION WHEN OTHERS THEN IF SQLCODE != -2289 THEN RAISE; END IF; END;
/

---------------------------
-- SEQUENCES
---------------------------
CREATE SEQUENCE centro_custo_seq START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE cliente_seq      START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE conta_seq        START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE reg_cont_seq     START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE vendas_seq       START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_dispositivo_iot START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_servico         START WITH 1 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_venda_evento    START WITH 1 INCREMENT BY 1 NOCACHE;

---------------------------
-- TABELAS BASE
---------------------------
CREATE TABLE cliente (
    id_cliente    NUMBER(5)       NOT NULL,
    nome_cliente  VARCHAR2(100)   NOT NULL,
    data_cadastro DATE            DEFAULT SYSDATE NOT NULL,
    cpf_cnpj      VARCHAR2(14)    NOT NULL,
    email         VARCHAR2(100)   NOT NULL,
    senha         VARCHAR2(100)   NOT NULL,
    ativo         CHAR(1)         DEFAULT 'S' NOT NULL,
    CONSTRAINT cliente_pk PRIMARY KEY (id_cliente),
    CONSTRAINT cliente_chk_ativo CHECK (ativo IN ('S','N')),
    CONSTRAINT cliente_cpf_cnpj_un UNIQUE (cpf_cnpj),
    CONSTRAINT cliente_email_un   UNIQUE (email)
);

CREATE TABLE centro_custo (
    id_centro_custo   NUMBER(4)    NOT NULL,
    nome_centro_custo VARCHAR2(70) NOT NULL,
    CONSTRAINT centro_custo_pk PRIMARY KEY (id_centro_custo)
);

CREATE TABLE conta_contabil (
    id_conta_contabil   NUMBER(4)    NOT NULL,
    nome_conta_contabil VARCHAR2(70) NOT NULL,
    tipo                CHAR(1)      NOT NULL,   -- 'R' (receita) | 'D' (despesa)
    cliente_id_cliente  NUMBER(5),
    CONSTRAINT conta_pk PRIMARY KEY (id_conta_contabil),
    CONSTRAINT conta_chk_tipo CHECK (tipo IN ('R','D'))
);
CREATE INDEX ix_conta_cliente ON conta_contabil (cliente_id_cliente);

CREATE TABLE reg_cont (
    id_reg_cont                  NUMBER(4)   NOT NULL,
    valor                        NUMBER(9,2) NOT NULL,
    conta_id_conta               NUMBER(4)   NOT NULL,
    centro_custo_id_centro_custo NUMBER(4)   NOT NULL,
    data_criacao                 DATE        DEFAULT SYSDATE,
    data_atualizacao             DATE,
    CONSTRAINT reg_cont_pk PRIMARY KEY (id_reg_cont)
);
CREATE INDEX ix_reg_cont_conta  ON reg_cont (conta_id_conta);
CREATE INDEX ix_reg_cont_ccusto ON reg_cont (centro_custo_id_centro_custo);

CREATE TABLE vendas (
    id_vendas              NUMBER(9) NOT NULL,
    cliente_id_cliente     NUMBER(5) NOT NULL,
    reg_cont_id_reg_cont   NUMBER(4) NOT NULL,
    venda_evento_id_evento NUMBER(12),
    CONSTRAINT vendas_pk PRIMARY KEY (id_vendas)
);
CREATE INDEX ix_vendas_cliente ON vendas (cliente_id_cliente);
CREATE INDEX ix_vendas_reg_cont ON vendas (reg_cont_id_reg_cont);
CREATE UNIQUE INDEX vendas__idx ON vendas (venda_evento_id_evento);

---------------------------
-- TABELAS IoT
---------------------------
CREATE TABLE dispositivo_iot (
    id_dispositivo NUMBER(6)    NOT NULL,
    nome           VARCHAR2(80) NOT NULL,
    tipo           VARCHAR2(20) DEFAULT 'ESP32' NOT NULL,
    ativo          CHAR(1)      DEFAULT 'S' NOT NULL,
    CONSTRAINT dispositivo_iot_pk PRIMARY KEY (id_dispositivo),
    CONSTRAINT dispositivo_iot_chk_ativo CHECK (ativo IN ('S','N'))
);

CREATE TABLE servico (
    id_servico     NUMBER(6)     NOT NULL,
    codigo         VARCHAR2(50)  NOT NULL,
    nome           VARCHAR2(120) NOT NULL,
    preco_padrao   NUMBER(9,2)   NOT NULL,
    ativo          CHAR(1)       DEFAULT 'S' NOT NULL,
    CONSTRAINT servico_pk PRIMARY KEY (id_servico),
    CONSTRAINT servico_codigo_un UNIQUE (codigo),
    CONSTRAINT servico_chk_ativo CHECK (ativo IN ('S','N'))
);

CREATE TABLE venda_evento (
    id_evento                      NUMBER(12)  NOT NULL,
    dispositivo_iot_id_dispositivo NUMBER(6)   NOT NULL,
    uid_tag                        VARCHAR2(32),
    servico_codigo                 VARCHAR2(50),
    servico_id_servico             NUMBER(6),
    cliente_id_cliente             NUMBER(5),
    operador_id                    NUMBER(5),
    quantidade                     NUMBER(9,2) DEFAULT 1 NOT NULL,
    valor_unitario                 NUMBER(9,2),
    valor_total                    NUMBER(9,2),
    origem                         VARCHAR2(20) DEFAULT 'RFID',
    dt_evento                      DATE        DEFAULT SYSDATE NOT NULL,
    payload_json                   CLOB,
    vendas_id_vendas               NUMBER(9),
    CONSTRAINT venda_evento_pk PRIMARY KEY (id_evento)
);
CREATE INDEX ix_venda_evento_disp    ON venda_evento (dispositivo_iot_id_dispositivo);
CREATE INDEX ix_venda_evento_serv    ON venda_evento (servico_id_servico);
CREATE INDEX ix_venda_evento_cliente ON venda_evento (cliente_id_cliente);
CREATE INDEX ix_venda_evento_dt      ON venda_evento (dt_evento);
CREATE UNIQUE INDEX venda_evento__idx ON venda_evento (vendas_id_vendas);

---------------------------
-- FKs
---------------------------
ALTER TABLE conta_contabil
  ADD CONSTRAINT conta_cliente_fk FOREIGN KEY (cliente_id_cliente)
      REFERENCES cliente (id_cliente) NOT DEFERRABLE;

ALTER TABLE reg_cont
  ADD CONSTRAINT reg_cont_conta_fk FOREIGN KEY (conta_id_conta)
      REFERENCES conta_contabil (id_conta_contabil) NOT DEFERRABLE;

ALTER TABLE reg_cont
  ADD CONSTRAINT reg_cont_centro_custo_fk FOREIGN KEY (centro_custo_id_centro_custo)
      REFERENCES centro_custo (id_centro_custo) NOT DEFERRABLE;

ALTER TABLE vendas
  ADD CONSTRAINT vendas_cliente_fk FOREIGN KEY (cliente_id_cliente)
      REFERENCES cliente (id_cliente) NOT DEFERRABLE;

ALTER TABLE vendas
  ADD CONSTRAINT vendas_reg_cont_fk FOREIGN KEY (reg_cont_id_reg_cont)
      REFERENCES reg_cont (id_reg_cont) NOT DEFERRABLE;

ALTER TABLE vendas
  ADD CONSTRAINT vendas_venda_evento_fk FOREIGN KEY (venda_evento_id_evento)
      REFERENCES venda_evento (id_evento) NOT DEFERRABLE;

ALTER TABLE venda_evento
  ADD CONSTRAINT venda_evento_dispositivo_fk FOREIGN KEY (dispositivo_iot_id_dispositivo)
      REFERENCES dispositivo_iot (id_dispositivo) NOT DEFERRABLE;

ALTER TABLE venda_evento
  ADD CONSTRAINT venda_evento_servico_fk FOREIGN KEY (servico_id_servico)
      REFERENCES servico (id_servico) NOT DEFERRABLE;

ALTER TABLE venda_evento
  ADD CONSTRAINT venda_evento_cliente_fk FOREIGN KEY (cliente_id_cliente)
      REFERENCES cliente (id_cliente) NOT DEFERRABLE;

ALTER TABLE venda_evento
  ADD CONSTRAINT venda_evento_vendas_fk FOREIGN KEY (vendas_id_vendas)
      REFERENCES vendas (id_vendas) NOT DEFERRABLE;

---------------------------
-- TRIGGER DE AUDITORIA REG_CONT
---------------------------
CREATE OR REPLACE TRIGGER trg_reg_cont_biu_aud
BEFORE INSERT OR UPDATE ON reg_cont
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
SHOW ERRORS

---------------------------
-- DEFAULTS (cliente/conta/ccusto padrão)
---------------------------
CREATE OR REPLACE PROCEDURE pr_setup_defaults AS
  v_exists NUMBER;
BEGIN
  -- Cliente genérico
  SELECT COUNT(*) INTO v_exists FROM cliente WHERE id_cliente = 99999;
  IF v_exists = 0 THEN
    INSERT INTO cliente(id_cliente, nome_cliente, cpf_cnpj, email, senha, ativo)
    VALUES (99999, 'CLIENTE GENERICO', '00000000000000', 'generico@example.com', '***', 'S');
  END IF;

  -- Centro de custo padrão
  SELECT COUNT(*) INTO v_exists FROM centro_custo WHERE id_centro_custo = 1001;
  IF v_exists = 0 THEN
    INSERT INTO centro_custo(id_centro_custo, nome_centro_custo)
    VALUES (1001, 'OPERACIONAL PADRAO');
  END IF;

  -- Conta de receita padrão (tipo R) em CONTA_CONTABIL
  SELECT COUNT(*) INTO v_exists FROM conta_contabil WHERE id_conta_contabil = 1001;
  IF v_exists = 0 THEN
    INSERT INTO conta_contabil(id_conta_contabil, nome_conta_contabil, tipo, cliente_id_cliente)
    VALUES (1001, 'RECEITA SERVICOS PADRAO', 'R', NULL);
  END IF;
END;
/
BEGIN pr_setup_defaults; END;
/

---------------------------
-- TRIGGER: cada VENDA_EVENTO -> cria REG_CONT + VENDAS e amarra IDs
---------------------------
CREATE OR REPLACE TRIGGER trg_venda_evento_ai
AFTER INSERT ON venda_evento
FOR EACH ROW
DECLARE
  v_servico_id   servico.id_servico%TYPE;
  v_preco_padrao servico.preco_padrao%TYPE := 0;
  v_qtd          NUMBER := 1;
  v_unit         NUMBER := 0;
  v_total        NUMBER := 0;
  v_cliente      cliente.id_cliente%TYPE;
  v_reg_cont_id  reg_cont.id_reg_cont%TYPE;
  v_venda_id     vendas.id_vendas%TYPE;
BEGIN
  -- Resolver serviço a partir de ID ou código
  v_servico_id := :NEW.servico_id_servico;
  IF v_servico_id IS NULL AND :NEW.servico_codigo IS NOT NULL THEN
    BEGIN
      SELECT id_servico INTO v_servico_id
        FROM servico
       WHERE UPPER(codigo) = UPPER(:NEW.servico_codigo);
    EXCEPTION WHEN NO_DATA_FOUND THEN
      v_servico_id := NULL;
    END;
  END IF;

  IF v_servico_id IS NOT NULL THEN
    SELECT NVL(preco_padrao,0) INTO v_preco_padrao FROM servico WHERE id_servico = v_servico_id;
  END IF;

  v_qtd   := NVL(:NEW.quantidade, 1);
  v_unit  := NVL(:NEW.valor_unitario, v_preco_padrao);
  v_total := NVL(:NEW.valor_total, v_qtd * v_unit);

  -- Cliente default se não vier no evento
  v_cliente := NVL(:NEW.cliente_id_cliente, 99999);

  -- REG_CONT (receita) com conta/centro padrão 1001
  v_reg_cont_id := reg_cont_seq.NEXTVAL;
  INSERT INTO reg_cont(id_reg_cont, valor, conta_id_conta, centro_custo_id_centro_custo)
  VALUES (v_reg_cont_id, NVL(v_total,0), 1001, 1001);

  -- VENDAS vinculada ao REG_CONT e ao cliente + referência ao evento
  v_venda_id := vendas_seq.NEXTVAL;
  INSERT INTO vendas(id_vendas, cliente_id_cliente, reg_cont_id_reg_cont, venda_evento_id_evento)
  VALUES (v_venda_id, v_cliente, v_reg_cont_id, :NEW.id_evento);

  -- Atualiza o evento com o ID da venda gerada (uma-a-uma opcional)
  UPDATE venda_evento
     SET vendas_id_vendas = v_venda_id
   WHERE id_evento = :NEW.id_evento;
END;
/
SHOW ERRORS

---------------------------
-- TRIGGER: fallback - se alguém inserir VENDAS sem REG_CONT, cria um
---------------------------
CREATE OR REPLACE TRIGGER trg_vendas_ai_ensure_regcont
AFTER INSERT ON vendas
FOR EACH ROW
DECLARE
  v_reg_cont_id reg_cont.id_reg_cont%TYPE;
BEGIN
  IF :NEW.reg_cont_id_reg_cont IS NULL THEN
    v_reg_cont_id := reg_cont_seq.NEXTVAL;
    INSERT INTO reg_cont(id_reg_cont, valor, conta_id_conta, centro_custo_id_centro_custo)
    VALUES (v_reg_cont_id, 0, 1001, 1001);

    UPDATE vendas
       SET reg_cont_id_reg_cont = v_reg_cont_id
     WHERE id_vendas = :NEW.id_vendas;
  END IF;
END;
/
SHOW ERRORS

-- FIM
