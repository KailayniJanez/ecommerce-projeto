-- =====================================================
-- SCRIPT DE CRIAÇÃO DO ESQUEMA DE E-COMMERCE
-- =====================================================

-- Criação do banco de dados
CREATE DATABASE IF NOT EXISTS ecommerce;
USE ecommerce;

-- =====================================================
-- TABELAS PRINCIPAIS
-- =====================================================

-- Tabela Cliente (Pessoa Física ou Jurídica)
CREATE TABLE cliente (
    id_cliente INT PRIMARY KEY AUTO_INCREMENT,
    tipo_cliente ENUM('PF', 'PJ') NOT NULL,
    nome_razao_social VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    telefone VARCHAR(20),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Campos PF
    cpf VARCHAR(14) UNIQUE,
    
    -- Campos PJ
    cnpj VARCHAR(18) UNIQUE,
    inscricao_estadual VARCHAR(20),
    
    -- CONSTRAINT para garantir que PF tem CPF e PJ tem CNPJ
    CONSTRAINT check_cliente_pf_pj CHECK (
        (tipo_cliente = 'PF' AND cpf IS NOT NULL AND cnpj IS NULL) OR
        (tipo_cliente = 'PJ' AND cnpj IS NOT NULL AND cpf IS NULL)
    )
);

-- Tabela Endereço
CREATE TABLE endereco (
    id_endereco INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    logradouro VARCHAR(150) NOT NULL,
    numero VARCHAR(10),
    complemento VARCHAR(50),
    bairro VARCHAR(50),
    cidade VARCHAR(50) NOT NULL,
    estado CHAR(2) NOT NULL,
    cep VARCHAR(10) NOT NULL,
    tipo_endereco ENUM('RESIDENCIAL', 'COMERCIAL', 'ENTREGA') DEFAULT 'ENTREGA',
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente) ON DELETE CASCADE
);

-- Tabela Fornecedor
CREATE TABLE fornecedor (
    id_fornecedor INT PRIMARY KEY AUTO_INCREMENT,
    razao_social VARCHAR(100) NOT NULL UNIQUE,
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    email VARCHAR(100),
    telefone VARCHAR(20),
    endereco VARCHAR(200),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabela Vendedor (Terceiro)
CREATE TABLE vendedor (
    id_vendedor INT PRIMARY KEY AUTO_INCREMENT,
    nome_fantasia VARCHAR(100) NOT NULL,
    razao_social VARCHAR(100) NOT NULL UNIQUE,
    cnpj VARCHAR(18) NOT NULL UNIQUE,
    email VARCHAR(100),
    telefone VARCHAR(20),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    eh_fornecedor BOOLEAN DEFAULT FALSE,
    id_fornecedor_ref INT,
    FOREIGN KEY (id_fornecedor_ref) REFERENCES fornecedor(id_fornecedor)
);

-- Tabela Produto
CREATE TABLE produto (
    id_produto INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(100) NOT NULL,
    descricao TEXT,
    categoria VARCHAR(50),
    valor_unitario DECIMAL(10,2) NOT NULL CHECK (valor_unitario > 0),
    peso_kg DECIMAL(8,3),
    dimensoes VARCHAR(50),
    data_cadastro TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ativo BOOLEAN DEFAULT TRUE
);

-- Tabela Estoque
CREATE TABLE estoque (
    id_estoque INT PRIMARY KEY AUTO_INCREMENT,
    nome_local VARCHAR(100) NOT NULL,
    endereco VARCHAR(200) NOT NULL,
    responsavel VARCHAR(100)
);

-- =====================================================
-- TABELAS DE RELACIONAMENTO (N:N)
-- =====================================================

-- Produto por Fornecedor
CREATE TABLE produto_fornecedor (
    id_produto INT,
    id_fornecedor INT,
    preco_custo DECIMAL(10,2),
    lead_time_dias INT DEFAULT 5,
    PRIMARY KEY (id_produto, id_fornecedor),
    FOREIGN KEY (id_produto) REFERENCES produto(id_produto),
    FOREIGN KEY (id_fornecedor) REFERENCES fornecedor(id_fornecedor)
);

-- Produto em Estoque
CREATE TABLE produto_estoque (
    id_produto INT,
    id_estoque INT,
    quantidade INT NOT NULL DEFAULT 0 CHECK (quantidade >= 0),
    PRIMARY KEY (id_produto, id_estoque),
    FOREIGN KEY (id_produto) REFERENCES produto(id_produto),
    FOREIGN KEY (id_estoque) REFERENCES estoque(id_estoque)
);

-- Produto por Vendedor (Terceiro)
CREATE TABLE produto_vendedor (
    id_produto INT,
    id_vendedor INT,
    preco_venda DECIMAL(10,2) NOT NULL,
    comissao_percent DECIMAL(5,2) DEFAULT 10.0,
    PRIMARY KEY (id_produto, id_vendedor),
    FOREIGN KEY (id_produto) REFERENCES produto(id_produto),
    FOREIGN KEY (id_vendedor) REFERENCES vendedor(id_vendedor)
);

-- =====================================================
-- TABELAS DE PEDIDOS E PAGAMENTOS
-- =====================================================

-- Pedido
CREATE TABLE pedido (
    id_pedido INT PRIMARY KEY AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    data_pedido TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_pedido ENUM('AGUARDANDO_PAGAMENTO', 'PAGO', 'EM_SEPARACAO', 
                       'ENVIADO', 'ENTREGUE', 'CANCELADO') DEFAULT 'AGUARDANDO_PAGAMENTO',
    valor_total DECIMAL(10,2) NOT NULL DEFAULT 0,
    valor_frete DECIMAL(10,2) DEFAULT 0,
    data_atualizacao TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
);

-- Item do Pedido
CREATE TABLE pedido_item (
    id_pedido INT,
    id_produto INT,
    quantidade INT NOT NULL CHECK (quantidade > 0),
    preco_unitario DECIMAL(10,2) NOT NULL,
    desconto DECIMAL(10,2) DEFAULT 0,
    PRIMARY KEY (id_pedido, id_produto),
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_produto) REFERENCES produto(id_produto)
);

-- Forma de Pagamento (múltiplas por pedido)
CREATE TABLE pagamento (
    id_pagamento INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    tipo_pagamento ENUM('CARTAO_CREDITO', 'CARTAO_DEBITO', 'BOLETO', 'PIX', 'TRANSFERENCIA') NOT NULL,
    valor_pago DECIMAL(10,2) NOT NULL CHECK (valor_pago > 0),
    parcelas INT DEFAULT 1,
    cartao_ultimos_digitos VARCHAR(4),
    status_pagamento ENUM('PENDENTE', 'APROVADO', 'RECUSADO', 'REEMBOLSADO') DEFAULT 'PENDENTE',
    data_pagamento TIMESTAMP NULL,
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido) ON DELETE CASCADE
);

-- Entrega
CREATE TABLE entrega (
    id_entrega INT PRIMARY KEY AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    id_endereco INT NOT NULL,
    codigo_rastreio VARCHAR(50) UNIQUE NOT NULL,
    status_entrega ENUM('PREPARANDO', 'ENVIADO', 'EM_TRANSITO', 'ENTREGUE', 'DEVOLVIDO') DEFAULT 'PREPARANDO',
    data_envio DATE,
    data_previsao_entrega DATE,
    data_entrega DATE,
    transportadora VARCHAR(50),
    FOREIGN KEY (id_pedido) REFERENCES pedido(id_pedido) ON DELETE CASCADE,
    FOREIGN KEY (id_endereco) REFERENCES endereco(id_endereco)
);

-- =====================================================
-- ÍNDICES PARA MELHOR PERFORMANCE
-- =====================================================

CREATE INDEX idx_cliente_tipo ON cliente(tipo_cliente);
CREATE INDEX idx_pedido_cliente ON pedido(id_cliente);
CREATE INDEX idx_pedido_status ON pedido(status_pedido);
CREATE INDEX idx_produto_categoria ON produto(categoria);
CREATE INDEX idx_entrega_rastreio ON entrega(codigo_rastreio);

-- =====================================================
-- INSERÇÃO DE DADOS PARA TESTES
-- =====================================================

-- Inserindo Clientes (Pessoa Física)
INSERT INTO cliente (tipo_cliente, nome_razao_social, email, telefone, cpf) VALUES
('PF', 'João Silva', 'joao.silva@email.com', '(11) 98765-4321', '123.456.789-00'),
('PF', 'Maria Oliveira', 'maria.oliveira@email.com', '(11) 91234-5678', '234.567.890-11'),
('PF', 'Carlos Santos', 'carlos.santos@email.com', '(21) 99876-5432', '345.678.901-22');

-- Inserindo Clientes (Pessoa Jurídica)
INSERT INTO cliente (tipo_cliente, nome_razao_social, email, telefone, cnpj, inscricao_estadual) VALUES
('PJ', 'Tech Solutions Ltda', 'contato@techsolutions.com', '(11) 3456-7890', '12.345.678/0001-90', '123.456.789'),
('PJ', 'Comércio Global S/A', 'vendas@comercioglobal.com', '(11) 4567-8901', '23.456.789/0001-01', '987.654.321');

-- Inserindo Endereços
INSERT INTO endereco (id_cliente, logradouro, numero, complemento, bairro, cidade, estado, cep, tipo_endereco) VALUES
(1, 'Rua das Flores', '100', 'Apto 101', 'Jardim América', 'São Paulo', 'SP', '01234-567', 'RESIDENCIAL'),
(1, 'Av. Paulista', '2000', 'Sala 301', 'Bela Vista', 'São Paulo', 'SP', '01310-100', 'ENTREGA'),
(2, 'Rua do Comércio', '500', NULL, 'Centro', 'Rio de Janeiro', 'RJ', '20010-010', 'ENTREGA'),
(3, 'Av. Brasil', '1500', 'Casa 2', 'Copacabana', 'Rio de Janeiro', 'RJ', '22020-020', 'RESIDENCIAL'),
(4, 'Rua da Tecnologia', '50', 'Andar 5', 'Vila Olímpia', 'São Paulo', 'SP', '04550-000', 'COMERCIAL'),
(5, 'Av. dos Negócios', '1000', 'Bloco A', 'Centro Empresarial', 'São Paulo', 'SP', '04550-001', 'COMERCIAL');

-- Inserindo Fornecedores
INSERT INTO fornecedor (razao_social, cnpj, email, telefone, endereco) VALUES
('Eletrônicos Importados Ltda', '34.567.890/0001-12', 'vendas@eletronicosimportados.com', '(11) 5678-9012', 'Rua do Comércio Exterior, 100 - SP'),
('Moda Brasil Indústria', '45.678.901/0001-23', 'contato@modabrasil.com', '(11) 6789-0123', 'Rua da Moda, 200 - SP'),
('Informática Nacional', '56.789.012/0001-34', 'vendas@informaticanacional.com', '(21) 7890-1234', 'Av. das Tecnologias, 300 - RJ'),
('Casa e Conforto Ltda', '67.890.123/0001-45', 'contato@casaconforto.com', '(11) 8901-2345', 'Rua dos Móveis, 400 - SP');

-- Inserindo Vendedores (alguns também são fornecedores)
INSERT INTO vendedor (nome_fantasia, razao_social, cnpj, email, telefone, eh_fornecedor, id_fornecedor_ref) VALUES
('TechSeller', 'TechSeller Comércio Eletrônico', '78.901.234/0001-56', 'vendas@techseller.com', '(11) 9012-3456', TRUE, 1),
('ModaOnline', 'ModaOnline Marketplace', '89.012.345/0001-67', 'contato@modaonline.com', '(11) 0123-4567', TRUE, 2),
('CasaBela', 'CasaBela Decorações', '90.123.456/0001-78', 'vendas@casabela.com', '(11) 1234-5678', FALSE, NULL),
('TecnoShop', 'TecnoShop Informática', '01.234.567/0001-89', 'contato@tecnoshop.com', '(11) 2345-6789', TRUE, 3);

-- Inserindo Produtos
INSERT INTO produto (nome, descricao, categoria, valor_unitario, peso_kg, dimensoes) VALUES
('Smartphone X100', 'Smartphone 128GB, 6GB RAM, Tela 6.5"', 'ELETRÔNICOS', 1999.99, 0.250, '16x8x1cm'),
('Notebook Pro 15', 'Notebook i7, 16GB RAM, SSD 512GB', 'INFORMÁTICA', 4999.99, 2.200, '36x25x3cm'),
('Camiseta Casual', 'Camiseta 100% algodão, vários tamanhos', 'VESTUÁRIO', 49.99, 0.200, '30x20x2cm'),
('Tênis Esportivo', 'Tênis para corrida, amortecimento', 'CALÇADOS', 199.99, 0.800, '35x25x12cm'),
('Fone Bluetooth', 'Fone de ouvido sem fio, bateria 20h', 'ELETRÔNICOS', 149.99, 0.150, '10x8x4cm'),
('Monitor 24"', 'Monitor LED Full HD, 75Hz', 'INFORMÁTICA', 899.99, 3.500, '55x40x15cm'),
('Sofá 3 Lugares', 'Sofá retrátil e reclinável', 'MÓVEIS', 1299.99, 35.000, '200x80x70cm'),
('Geladeira Frost Free', 'Geladeira 400L, Inox', 'ELETRODOMÉSTICOS', 3499.99, 65.000, '180x75x70cm');

-- Relacionando Produtos com Fornecedores
INSERT INTO produto_fornecedor (id_produto, id_fornecedor, preco_custo, lead_time_dias) VALUES
(1, 1, 1500.00, 10),
(2, 3, 3800.00, 15),
(3, 2, 25.00, 5),
(4, 2, 120.00, 7),
(5, 1, 90.00, 8),
(6, 3, 650.00, 10),
(7, 4, 950.00, 20),
(8, 4, 2600.00, 15);

-- Relacionando Produtos com Vendedores
INSERT INTO produto_vendedor (id_produto, id_vendedor, preco_venda, comissao_percent) VALUES
(1, 1, 2099.99, 8.0),
(1, 4, 2049.99, 7.5),
(2, 4, 4899.99, 10.0),
(3, 2, 59.99, 12.0),
(4, 2, 219.99, 12.0),
(5, 1, 159.99, 8.0),
(6, 4, 949.99, 8.0),
(7, 3, 1399.99, 15.0);

-- Criando Estoques
INSERT INTO estoque (nome_local, endereco, responsavel) VALUES
('CD São Paulo - Zona Sul', 'Rua dos Armazéns, 1000 - SP', 'João Estoque'),
('CD Rio de Janeiro', 'Av. das Mercadorias, 500 - RJ', 'Maria Logística'),
('CD São Paulo - Zona Norte', 'Rua do Transporte, 2000 - SP', 'Carlos Distribuição');

-- Relacionando Produtos com Estoques
INSERT INTO produto_estoque (id_produto, id_estoque, quantidade) VALUES
(1, 1, 150), (2, 1, 50), (3, 1, 500), (4, 1, 200),
(5, 1, 300), (6, 1, 80), (7, 1, 30), (8, 1, 20),
(1, 2, 80), (2, 2, 30), (3, 2, 300), (4, 2, 150),
(5, 2, 200), (6, 2, 40), (7, 2, 15), (8, 2, 10),
(3, 3, 400), (4, 3, 180), (5, 3, 250);

-- Inserindo Pedidos
INSERT INTO pedido (id_cliente, status_pedido, valor_total, valor_frete) VALUES
(1, 'ENTREGUE', 2249.98, 30.00),
(2, 'ENVIADO', 99.98, 15.00),
(3, 'PAGO', 4999.99, 50.00),
(4, 'AGUARDANDO_PAGAMENTO', 149.99, 10.00),
(5, 'EM_SEPARACAO', 1299.99, 80.00),
(1, 'PAGO', 1899.98, 25.00);

-- Inserindo Itens dos Pedidos
INSERT INTO pedido_item (id_pedido, id_produto, quantidade, preco_unitario, desconto) VALUES
(1, 1, 1, 1999.99, 0),
(1, 5, 1, 149.99, 0),
(2, 3, 2, 49.99, 0),
(3, 2, 1, 4999.99, 0),
(4, 5, 1, 149.99, 0),
(5, 7, 1, 1299.99, 0),
(6, 1, 1, 1999.99, 100.00),
(6, 5, 1, 149.99, 50.00);

-- Inserindo Pagamentos (múltiplas formas por pedido)
INSERT INTO pagamento (id_pedido, tipo_pagamento, valor_pago, parcelas, cartao_ultimos_digitos, status_pagamento, data_pagamento) VALUES
(1, 'CARTAO_CREDITO', 2249.98, 3, '1234', 'APROVADO', '2024-01-15 10:30:00'),
(2, 'PIX', 99.98, 1, NULL, 'APROVADO', '2024-01-20 14:45:00'),
(3, 'BOLETO', 4999.99, 1, NULL, 'APROVADO', '2024-01-25 09:00:00'),
(4, 'CARTAO_DEBITO', 149.99, 1, '5678', 'PENDENTE', NULL),
(5, 'CARTAO_CREDITO', 1299.99, 6, '9012', 'APROVADO', '2024-02-01 16:20:00'),
(6, 'PIX', 949.99, 1, NULL, 'APROVADO', '2024-02-05 11:15:00'),
(6, 'CARTAO_CREDITO', 1050.00, 2, '3456', 'APROVADO', '2024-02-05 11:16:00');  -- Pagamento dividido em duas formas

-- Inserindo Entregas
INSERT INTO entrega (id_pedido, id_endereco, codigo_rastreio, status_entrega, data_envio, data_previsao_entrega, data_entrega, transportadora) VALUES
(1, 2, 'BR123456789', 'ENTREGUE', '2024-01-16', '2024-01-20', '2024-01-19', 'Correios'),
(2, 3, 'BR987654321', 'EM_TRANSITO', '2024-01-21', '2024-01-25', NULL, 'Jadlog'),
(3, 4, 'BR456789123', 'ENVIADO', '2024-01-26', '2024-01-30', NULL, 'Correios'),
(5, 6, 'BR789123456', 'PREPARANDO', NULL, '2024-02-10', NULL, 'Transportadora Rápida'),
(6, 2, 'BR321654987', 'ENVIADO', '2024-02-06', '2024-02-10', NULL, 'Jadlog');

-- =====================================================
-- QUERIES SQL COMPLEXAS
-- =====================================================

-- 1. RECUPERAÇÃO SIMPLES COM SELECT: Listar todos os produtos ativos com preço acima de R$100
SELECT id_produto, nome, categoria, valor_unitario 
FROM produto 
WHERE ativo = TRUE AND valor_unitario > 100
ORDER BY valor_unitario DESC;

-- 2. FILTROS COM WHERE: Pedidos com status específico e valor total acima de média
SELECT p.id_pedido, c.nome_razao_social, p.status_pedido, p.valor_total
FROM pedido p
INNER JOIN cliente c ON p.id_cliente = c.id_cliente
WHERE p.status_pedido IN ('PAGO', 'EM_SEPARACAO') 
  AND p.valor_total > (SELECT AVG(valor_total) FROM pedido)
ORDER BY p.valor_total DESC;

-- 3. EXPRESSÃO PARA ATRIBUTO DERIVADO: Calcular valor real com desconto dos itens
SELECT 
    pi.id_pedido,
    p.nome AS produto,
    pi.quantidade,
    pi.preco_unitario,
    pi.desconto,
    (pi.quantidade * pi.preco_unitario - pi.desconto) AS valor_real,
    ROUND((pi.desconto / (pi.quantidade * pi.preco_unitario)) * 100, 2) AS percentual_desconto
FROM pedido_item pi
INNER JOIN produto p ON pi.id_produto = p.id_produto
WHERE pi.desconto > 0
ORDER BY percentual_desconto DESC;

-- 4. ORDENAÇÃO COM ORDER BY: Listagem de clientes por volume de compras
SELECT 
    c.id_cliente,
    c.nome_razao_social,
    c.tipo_cliente,
    COUNT(p.id_pedido) AS total_pedidos,
    SUM(p.valor_total) AS total_gasto,
    ROUND(AVG(p.valor_total), 2) AS ticket_medio
FROM cliente c
LEFT JOIN pedido p ON c.id_cliente = p.id_cliente
GROUP BY c.id_cliente, c.nome_razao_social, c.tipo_cliente
ORDER BY total_gasto DESC NULLS LAST;

-- 5. HAVING STATEMENT: Produtos com quantidade vendida acima da média
SELECT 
    p.id_produto,
    p.nome,
    SUM(pi.quantidade) AS quantidade_vendida,
    COUNT(DISTINCT pi.id_pedido) AS qtde_pedidos
FROM produto p
INNER JOIN pedido_item pi ON p.id_produto = pi.id_produto
INNER JOIN pedido ped ON pi.id_pedido = ped.id_pedido
WHERE ped.status_pedido NOT IN ('CANCELADO')
GROUP BY p.id_produto, p.nome
HAVING SUM(pi.quantidade) > (
    SELECT AVG(quantidade_vendida) 
    FROM (
        SELECT SUM(pi2.quantidade) AS quantidade_vendida
        FROM pedido_item pi2
        INNER JOIN pedido ped2 ON pi2.id_pedido = ped2.id_pedido
        WHERE ped2.status_pedido NOT IN ('CANCELADO')
        GROUP BY pi2.id_produto
    ) AS media_produtos
)
ORDER BY quantidade_vendida DESC;

-- 6. JUNÇÕES COMPLEXAS: Relação completa de pedidos com produtos, pagamentos e entregas
SELECT 
    ped.id_pedido,
    cli.nome_razao_social AS cliente,
    ped.data_pedido,
    ped.status_pedido,
    ped.valor_total,
    ped.valor_frete,
    prod.nome AS produto,
    pi.quantidade,
    pi.preco_unitario,
    GROUP_CONCAT(DISTINCT CONCAT(pag.tipo_pagamento, ': R$', pag.valor_pago) SEPARATOR ' | ') AS formas_pagamento,
    ent.codigo_rastreio,
    ent.status_entrega,
    ent.transportadora,
    ent.data_previsao_entrega
FROM pedido ped
INNER JOIN cliente cli ON ped.id_cliente = cli.id_cliente
INNER JOIN pedido_item pi ON ped.id_pedido = pi.id_pedido
INNER JOIN produto prod ON pi.id_produto = prod.id_produto
LEFT JOIN pagamento pag ON ped.id_pedido = pag.id_pagamento
LEFT JOIN entrega ent ON ped.id_pedido = ent.id_pedido
WHERE ped.data_pedido >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY ped.id_pedido, cli.nome_razao_social, ped.data_pedido, 
         ped.status_pedido, ped.valor_total, ped.valor_frete,
         prod.nome, pi.quantidade, pi.preco_unitario,
         ent.codigo_rastreio, ent.status_entrega, ent.transportadora,
         ent.data_previsao_entrega
ORDER BY ped.data_pedido DESC
LIMIT 20;

-- 7. PERGUNTA: Algum vendedor também é fornecedor?
SELECT 
    v.id_vendedor,
    v.nome_fantasia,
    v.razao_social,
    v.cnpj,
    f.razao_social AS fornecedor_vinculado,
    CASE WHEN v.eh_fornecedor = TRUE THEN 'Sim' ELSE 'Não' END AS eh_fornecedor
FROM vendedor v
LEFT JOIN fornecedor f ON v.id_fornecedor_ref = f.id_fornecedor
WHERE v.eh_fornecedor = TRUE;

-- 8. PERGUNTA: Relação de produtos, fornecedores e estoques (visão completa de supply chain)
SELECT 
    p.id_produto,
    p.nome AS produto,
    p.categoria,
    p.valor_unitario,
    f.razao_social AS fornecedor,
    pf.preco_custo,
    pf.lead_time_dias,
    e.nome_local AS local_estoque,
    pe.quantidade AS quantidade_estoque,
    (pe.quantidade * pf.preco_custo) AS valor_total_estoque,
    CASE 
        WHEN pe.quantidade < 50 THEN 'Estoque Crítico'
        WHEN pe.quantidade < 100 THEN 'Estoque Baixo'
        WHEN pe.quantidade < 300 THEN 'Estoque Adequado'
        ELSE 'Estoque Alto'
    END AS classificacao_estoque
FROM produto p
INNER JOIN produto_fornecedor pf ON p.id_produto = pf.id_produto
INNER JOIN fornecedor f ON pf.id_fornecedor = f.id_fornecedor
LEFT JOIN produto_estoque pe ON p.id_produto = pe.id_produto
LEFT JOIN estoque e ON pe.id_estoque = e.id_estoque
ORDER BY classificacao_estoque, p.categoria, p.nome;

-- 9. Análise de desempenho de entregas (atributo derivado)
SELECT 
    e.id_entrega,
    ped.id_pedido,
    c.nome_razao_social,
    e.transportadora,
    e.data_envio,
    e.data_entrega,
    e.data_previsao_entrega,
    DATEDIFF(e.data_entrega, e.data_envio) AS dias_transporte_real,
    DATEDIFF(e.data_previsao_entrega, e.data_envio) AS dias_transporte_previsto,
    CASE 
        WHEN e.data_entrega <= e.data_previsao_entrega THEN 'No Prazo'
        ELSE 'Atrasado'
    END AS status_prazo,
    ABS(DATEDIFF(e.data_entrega, e.data_previsao_entrega)) AS dias_diferenca
FROM entrega e
INNER JOIN pedido ped ON e.id_pedido = ped.id_pedido
INNER JOIN cliente c ON ped.id_cliente = c.id_cliente
WHERE e.data_entrega IS NOT NULL
ORDER BY status_prazo, dias_diferenca DESC;

-- 10. Ranking de vendedores por volume de vendas
SELECT 
    v.id_vendedor,
    v.nome_fantasia,
    COUNT(DISTINCT pi.id_pedido) AS pedidos_mediados,
    SUM(pi.quantidade * pi.preco_unitario) AS valor_bruto_vendido,
    ROUND(SUM(pi.quantidade * pi.preco_unitario * (pv.comissao_percent / 100)), 2) AS valor_comissao,
    ROUND(SUM(pi.quantidade * pi.preco_unitario * (1 - pv.comissao_percent / 100)), 2) AS valor_recebido_plataforma
FROM vendedor v
INNER JOIN produto_vendedor pv ON v.id_vendedor = pv.id_vendedor
INNER JOIN pedido_item pi ON pv.id_produto = pi.id_produto
INNER JOIN pedido ped ON pi.id_pedido = ped.id_pedido
WHERE ped.status_pedido = 'ENTREGUE'
GROUP BY v.id_vendedor, v.nome_fantasia
ORDER BY valor_bruto_vendido DESC;

-- 11. Produtos com maior margem de lucro (fornecedor vs venda)
SELECT 
    p.id_produto,
    p.nome,
    p.categoria,
    f.razao_social AS fornecedor_principal,
    pf.preco_custo,
    p.valor_unitario AS preco_venda_padrao,
    (p.valor_unitario - pf.preco_custo) AS lucro_bruto_unitario,
    ROUND(((p.valor_unitario - pf.preco_custo) / p.valor_unitario) * 100, 2) AS margem_percentual
FROM produto p
INNER JOIN produto_fornecedor pf ON p.id_produto = pf.id_produto
INNER JOIN fornecedor f ON pf.id_fornecedor = f.id_fornecedor
WHERE p.ativo = TRUE
ORDER BY margem_percentual DESC;

-- 12. Clientes com pagamentos parcelados e análise de parcelamento
SELECT 
    c.nome_razao_social,
    c.tipo_cliente,
    ped.id_pedido,
    ped.valor_total,
    pag.parcelas,
    pag.tipo_pagamento,
    pag.valor_pago,
    pag.valor_pago / pag.parcelas AS valor_parcela,
    ped.data_pedido,
    DATE_ADD(ped.data_pedido, INTERVAL pag.parcelas MONTH) AS data_ultima_parcela
FROM cliente c
INNER JOIN pedido ped ON c.id_cliente = ped.id_cliente
INNER JOIN pagamento pag ON ped.id_pedido = pag.id_pedido
WHERE pag.parcelas > 1
  AND pag.status_pagamento = 'APROVADO'
ORDER BY pag.parcelas DESC, ped.valor_total DESC;

-- 13. Análise de estoque por categoria (GROUP BY com HAVING)
SELECT 
    p.categoria,
    COUNT(DISTINCT p.id_produto) AS qtde_produtos,
    SUM(pe.quantidade) AS total_unidades_estoque,
    SUM(pe.quantidade * pf.preco_custo) AS valor_total_estoque,
    AVG(pe.quantidade) AS media_estoque_por_produto
FROM produto p
INNER JOIN produto_estoque pe ON p.id_produto = pe.id_produto
INNER JOIN produto_fornecedor pf ON p.id_produto = pf.id_produto
GROUP BY p.categoria
HAVING SUM(pe.quantidade) > 100
ORDER BY valor_total_estoque DESC;

-- 14. Pedidos com múltiplas formas de pagamento
SELECT 
    ped.id_pedido,
    c.nome_razao_social,
    COUNT(pag.id_pagamento) AS formas_pagamento_utilizadas,
    GROUP_CONCAT(DISTINCT pag.tipo_pagamento) AS tipos_pagamento,
    SUM(pag.valor_pago) AS total_pago,
    ped.valor_total,
    CASE 
        WHEN SUM(pag.valor_pago) = ped.valor_total THEN 'Pago Integralmente'
        WHEN SUM(pag.valor_pago) > ped.valor_total THEN 'Pagamento Excedente'
        ELSE 'Pagamento Parcial'
    END AS situacao_pagamento
FROM pedido ped
INNER JOIN cliente c ON ped.id_cliente = c.id_cliente
INNER JOIN pagamento pag ON ped.id_pedido = pag.id_pedido
GROUP BY ped.id_pedido, c.nome_razao_social, ped.valor_total
HAVING COUNT(pag.id_pagamento) > 1
ORDER BY formas_pagamento_utilizadas DESC;

-- 15. Visão executiva: Top 5 produtos mais vendidos por categoria
SELECT 
    categoria,
    nome AS produto_mais_vendido,
    quantidade_total,
    faturamento_total,
    ranking
FROM (
    SELECT 
        p.categoria,
        p.nome,
        SUM(pi.quantidade) AS quantidade_total,
        SUM(pi.quantidade * pi.preco_unitario) AS faturamento_total,
        ROW_NUMBER() OVER (PARTITION BY p.categoria ORDER BY SUM(pi.quantidade) DESC) AS ranking
    FROM produto p
    INNER JOIN pedido_item pi ON p.id_produto = pi.id_produto
    INNER JOIN pedido ped ON pi.id_pedido = ped.id_pedido
    WHERE ped.status_pedido NOT IN ('CANCELADO', 'AGUARDANDO_PAGAMENTO')
    GROUP BY p.categoria, p.id_produto, p.nome
) AS ranking_produtos
WHERE ranking <= 5
ORDER BY categoria, ranking;
