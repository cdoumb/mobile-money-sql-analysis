-- ============================================================
-- Mobile Money — Business SQL Queries
-- 15 requêtes organisées par thème métier
-- Concepts: SELECT, WHERE, JOIN, GROUP BY, HAVING, subqueries
-- ============================================================


-- ============================================================
-- THEME 1 : VOLUME & ACTIVITE GLOBALE
-- ============================================================

-- Q1. Volume total et montant par type de transaction
SELECT
    tt.type_name,
    COUNT(t.transaction_id)         AS nb_transactions,
    ROUND(SUM(t.amount), 2)         AS volume_total_fcfa,
    ROUND(AVG(t.amount), 2)         AS montant_moyen_fcfa
FROM transactions t
JOIN transaction_types tt ON t.type_id = tt.type_id
GROUP BY tt.type_name
ORDER BY volume_total_fcfa DESC;


-- Q2. Nombre de transactions par mois
SELECT
    DATE_TRUNC('month', created_at) AS mois,
    COUNT(*)                        AS nb_transactions,
    ROUND(SUM(amount), 2)           AS volume_fcfa
FROM transactions
GROUP BY mois
ORDER BY mois;


-- Q3. Top 5 clients les plus actifs (par nombre de transactions)
SELECT
    c.client_id,
    c.name,
    c.region,
    COUNT(t.transaction_id)  AS nb_transactions,
    ROUND(SUM(t.amount), 2)  AS volume_total_fcfa
FROM clients c
JOIN transactions t ON c.client_id = t.client_id
GROUP BY c.client_id, c.name, c.region
ORDER BY nb_transactions DESC
LIMIT 5;


-- ============================================================
-- THEME 2 : ANALYSE PAR REGION
-- ============================================================

-- Q4. Volume de transactions par région
SELECT
    c.region,
    COUNT(t.transaction_id)  AS nb_transactions,
    ROUND(SUM(t.amount), 2)  AS volume_total_fcfa
FROM transactions t
JOIN clients c ON t.client_id = c.client_id
GROUP BY c.region
ORDER BY volume_total_fcfa DESC;


-- Q5. Régions avec plus de 20 transactions (filtre HAVING)
SELECT
    c.region,
    COUNT(t.transaction_id) AS nb_transactions
FROM transactions t
JOIN clients c ON t.client_id = c.client_id
GROUP BY c.region
HAVING COUNT(t.transaction_id) > 20
ORDER BY nb_transactions DESC;


-- ============================================================
-- THEME 3 : ANALYSE MARCHANDS
-- ============================================================

-- Q6. Top 5 marchands par volume de paiements
SELECT
    m.name                    AS marchand,
    m.category,
    COUNT(t.transaction_id)   AS nb_paiements,
    ROUND(SUM(t.amount), 2)   AS volume_fcfa
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
WHERE t.type_id = (SELECT type_id FROM transaction_types WHERE type_name = 'PAYMENT')
GROUP BY m.merchant_id, m.name, m.category
ORDER BY volume_fcfa DESC
LIMIT 5;


-- Q7. Montant moyen par catégorie de marchand
SELECT
    m.category,
    COUNT(t.transaction_id)  AS nb_paiements,
    ROUND(AVG(t.amount), 2)  AS montant_moyen_fcfa
FROM transactions t
JOIN merchants m ON t.merchant_id = m.merchant_id
GROUP BY m.category
ORDER BY montant_moyen_fcfa DESC;


-- ============================================================
-- THEME 4 : DETECTION DE FRAUDE
-- ============================================================

-- Q8. Taux de fraude par type de transaction
SELECT
    tt.type_name,
    COUNT(*)                                                AS total_transactions,
    SUM(CASE WHEN t.is_fraud THEN 1 ELSE 0 END)            AS nb_fraudes,
    ROUND(
        100.0 * SUM(CASE WHEN t.is_fraud THEN 1 ELSE 0 END) / COUNT(*),
    2)                                                       AS taux_fraude_pct
FROM transactions t
JOIN transaction_types tt ON t.type_id = tt.type_id
GROUP BY tt.type_name
ORDER BY taux_fraude_pct DESC;


-- Q9. Transactions frauduleuses avec détail client et alerte
SELECT
    t.transaction_id,
    c.name              AS client,
    c.region,
    tt.type_name        AS type_transaction,
    t.amount,
    t.created_at,
    fa.alert_type,
    fa.severity,
    fa.reviewed
FROM transactions t
JOIN clients c              ON t.client_id = c.client_id
JOIN transaction_types tt   ON t.type_id = tt.type_id
JOIN fraud_alerts fa        ON t.transaction_id = fa.transaction_id
WHERE t.is_fraud = TRUE
ORDER BY fa.severity DESC, t.amount DESC;


-- Q10. Alertes non traitées par niveau de sévérité
SELECT
    severity,
    COUNT(*) AS nb_alertes_en_attente
FROM fraud_alerts
WHERE reviewed = FALSE
GROUP BY severity
ORDER BY
    CASE severity WHEN 'HIGH' THEN 1 WHEN 'MEDIUM' THEN 2 ELSE 3 END;


-- Q11. Clients ayant eu au moins une transaction frauduleuse
--      (subquery)
SELECT
    c.client_id,
    c.name,
    c.region,
    c.account_type
FROM clients c
WHERE c.client_id IN (
    SELECT DISTINCT t.client_id
    FROM transactions t
    WHERE t.is_fraud = TRUE
)
ORDER BY c.name;


-- ============================================================
-- THEME 5 : SANTE FINANCIERE DES COMPTES
-- ============================================================

-- Q12. Clients avec solde final négatif (balance drain)
SELECT
    c.name,
    c.region,
    t.transaction_id,
    t.amount,
    t.old_balance,
    t.new_balance
FROM transactions t
JOIN clients c ON t.client_id = c.client_id
WHERE t.new_balance < 0
ORDER BY t.new_balance ASC;


-- Q13. Transactions au-dessus du montant moyen global
--      (subquery scalaire)
SELECT
    t.transaction_id,
    c.name          AS client,
    tt.type_name    AS type_transaction,
    t.amount,
    t.created_at
FROM transactions t
JOIN clients c            ON t.client_id = c.client_id
JOIN transaction_types tt ON t.type_id = tt.type_id
WHERE t.amount > (SELECT AVG(amount) FROM transactions)
ORDER BY t.amount DESC
LIMIT 20;


-- Q14. Résumé complet par client : transactions, volume, fraudes
SELECT
    c.client_id,
    c.name,
    c.region,
    COUNT(t.transaction_id)                                      AS total_transactions,
    ROUND(SUM(t.amount), 2)                                      AS volume_total_fcfa,
    ROUND(AVG(t.amount), 2)                                      AS montant_moyen_fcfa,
    SUM(CASE WHEN t.is_fraud THEN 1 ELSE 0 END)                  AS nb_fraudes
FROM clients c
LEFT JOIN transactions t ON c.client_id = t.client_id
GROUP BY c.client_id, c.name, c.region
ORDER BY volume_total_fcfa DESC NULLS LAST;


-- Q15. Transactions CASH_OUT ou TRANSFER de plus de 100 000 FCFA
--       non encore signalées comme fraude → transactions suspectes
SELECT
    t.transaction_id,
    c.name              AS client,
    c.region,
    tt.type_name,
    t.amount,
    t.old_balance,
    t.new_balance,
    t.created_at
FROM transactions t
JOIN clients c            ON t.client_id = c.client_id
JOIN transaction_types tt ON t.type_id = tt.type_id
WHERE tt.type_name IN ('CASH_OUT', 'TRANSFER')
  AND t.amount > 100000
  AND t.is_fraud = FALSE
  AND t.transaction_id NOT IN (
      SELECT transaction_id FROM fraud_alerts
  )
ORDER BY t.amount DESC;
