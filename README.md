# 🛒 E-Commerce Database - Projeto de Banco de Dados

## 📋 Descrição do Projeto

Este projeto consiste no desenvolvimento de um esquema lógico de banco de dados para um sistema de e-commerce, aplicando os conceitos de modelagem de dados, mapeamento de modelos EER e implementação de consultas SQL complexas.

## 🎯 Objetivos

- Modelar um banco de dados relacional para e-commerce
- Implementar restrições e relacionamentos conforme regras de negócio
- Criar queries SQL com diferentes níveis de complexidade
- Demonstrar o uso de cláusulas avançadas do SQL

## 📊 Modelagem do Banco de Dados

### Regras de Negócio Implementadas

- **Clientes**: Uma conta pode ser Pessoa Física (PF) ou Jurídica (PJ), não podendo ter ambas as informações simultaneamente
- **Pagamento**: Cada pedido pode ter múltiplas formas de pagamento
- **Entrega**: Possui status de rastreamento e código de rastreio
- **Estoque**: Produtos podem estar em múltiplos locais de estoque
- **Fornecedores e Vendedores**: Relacionamento entre fornecedores e vendedores terceiros

### Estrutura do Banco de Dados

#### Tabelas Principais
- `cliente` - Armazena clientes PF e PJ
- `endereco` - Endereços dos clientes
- `produto` - Catálogo de produtos
- `pedido` - Pedidos realizados
- `pedido_item` - Itens de cada pedido
- `pagamento` - Formas de pagamento (múltiplas por pedido)
- `entrega` - Informações de entrega e rastreio
- `fornecedor` - Fornecedores dos produtos
- `vendedor` - Vendedores terceiros
- `estoque` - Locais de estoque

#### Tabelas de Relacionamento (N:N)
- `produto_fornecedor` - Relação produto-fornecedor
- `produto_estoque` - Controle de estoque por local
- `produto_vendedor` - Produtos vendidos por terceiros


## Queries Incluídas
- SELECT simples: listagem de produtos ativos
- WHERE: pedidos com valor acima da média
- Atributo derivado: cálculo de desconto e margem de lucro
- ORDER BY: ranking de clientes por gasto
- HAVING: produtos com vendas acima da média
- JOINs: relatório completo de pedidos com pagamentos e entregas

## Perguntas Respondidas
1. Quantos pedidos foram feitos por cada cliente?
2. Algum vendedor também é fornecedor?
3. Relação de produtos, fornecedores e estoques
4. Quais produtos têm maior margem de lucro?
5. Qual transportadora tem melhor prazo de entrega?

## Arquivos
- ecommerce.sql (script completo)
- README.md (este arquivo)

## Autor
Kailayni Janez
