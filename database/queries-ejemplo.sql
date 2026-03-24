-- =====================================================
-- Queries de ejemplo útiles
-- FormalizeSE Hub - Sistema de Facturación Electrónica
-- =====================================================

-- =====================================================
-- 1. CONSULTAS BÁSICAS
-- =====================================================

-- Ver todos los clientes activos
SELECT 
  id, 
  nombre, 
  nit, 
  email, 
  activo,
  prefijo_facturas,
  configuracion_json
FROM clientes 
WHERE deleted_at IS NULL
ORDER BY nombre;

-- Ver todos los proveedores activos
SELECT 
  id, 
  nit, 
  nombre, 
  email, 
  contacto_principal, 
  activo 
FROM proveedores 
WHERE deleted_at IS NULL
ORDER BY nombre;

-- Ver plan contable de un cliente (solo cuentas auxiliares que aceptan movimientos)
SELECT 
  codigo_cuenta,
  nombre_cuenta,
  tipo_cuenta,
  nivel_cuenta,
  naturaleza_cuenta,
  activa
FROM cuentas_contables
WHERE cliente_id = 'cliente-001'
  AND acepta_movimientos = true
  AND deleted_at IS NULL
ORDER BY codigo_cuenta;

-- =====================================================
-- 2. PLAN CONTABLE JERÁRQUICO
-- =====================================================

-- Ver plan contable completo con jerarquía indentada
SELECT 
  codigo_indentado,
  nombre_indentado,
  tipo_cuenta,
  nivel_cuenta,
  acepta_movimientos,
  activa
FROM v_plan_contable_jerarquico
WHERE cliente_id = 'cliente-001'
ORDER BY ruta;

-- Ver solo las clases principales (nivel 1)
SELECT 
  codigo_cuenta,
  nombre_cuenta,
  tipo_cuenta,
  naturaleza_cuenta
FROM cuentas_contables
WHERE cliente_id = 'cliente-001'
  AND nivel_cuenta = 1
  AND deleted_at IS NULL
ORDER BY codigo_cuenta;

-- Ver todas las cuentas hijas de una cuenta específica
SELECT 
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  cc.nivel_cuenta,
  cc.acepta_movimientos
FROM cuentas_contables cc
WHERE cc.cuenta_padre_id = 'cuenta-006' -- Cambiar por ID de cuenta padre
  AND cc.deleted_at IS NULL
ORDER BY cc.codigo_cuenta;

-- Obtener la ruta completa de una cuenta específica
SELECT obtener_ruta_cuenta('cuenta-012');

-- =====================================================
-- 3. PARAMETRIZACIÓN DE PROVEEDORES
-- =====================================================

-- Ver cuentas parametrizadas de un proveedor (con prioridad)
SELECT 
  p.nombre as proveedor,
  p.nit,
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  cc.tipo_cuenta,
  pcc.prioridad,
  pcc.activo as parametrizacion_activa,
  pcc.notas
FROM proveedor_por_cuenta_contable pcc
JOIN proveedores p ON pcc.proveedor_id = p.id
JOIN cuentas_contables cc ON pcc.cuenta_contable_id = cc.id
WHERE p.id = 'proveedor-001'
  AND pcc.activo = true
  AND cc.deleted_at IS NULL
ORDER BY pcc.prioridad ASC;

-- Ver todos los proveedores asociados a una cuenta contable
SELECT 
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  p.nit,
  p.nombre as proveedor,
  pcc.prioridad,
  pcc.activo
FROM proveedor_por_cuenta_contable pcc
JOIN cuentas_contables cc ON pcc.cuenta_contable_id = cc.id
JOIN proveedores p ON pcc.proveedor_id = p.id
WHERE cc.codigo_cuenta = '510506' -- Cambiar por código de cuenta
  AND pcc.activo = true
  AND cc.deleted_at IS NULL
  AND p.deleted_at IS NULL
ORDER BY pcc.prioridad;

-- Obtener cuenta sugerida para un proveedor
SELECT * FROM sugerir_cuenta_para_proveedor('proveedor-001');

-- Proveedores sin cuentas parametrizadas
SELECT 
  p.id,
  p.nit,
  p.nombre,
  p.email,
  p.activo
FROM proveedores p
LEFT JOIN proveedor_por_cuenta_contable pcc ON p.id = pcc.proveedor_id AND pcc.activo = true
WHERE pcc.id IS NULL
  AND p.deleted_at IS NULL
  AND p.activo = true
ORDER BY p.nombre;

-- =====================================================
-- 4. DESCARGAS DE FACTURAS (DIAN)
-- =====================================================

-- Ver todas las descargas con sus estadísticas
SELECT * FROM v_resumen_descargas
ORDER BY created_at DESC
LIMIT 20;

-- Ver descargas completadas
SELECT 
  id,
  fecha_inicio,
  fecha_fin,
  total_facturas,
  facturas_procesadas,
  facturas_con_errores,
  total_xmls,
  tiempo_procesamiento,
  usuario_id
FROM descargas
WHERE estado = 'COMPLETADO'
ORDER BY created_at DESC;

-- Ver descargas con errores
SELECT 
  id,
  fecha_inicio,
  fecha_fin,
  total_facturas,
  facturas_con_errores,
  usuario_id,
  created_at
FROM descargas
WHERE estado = 'ERROR' 
   OR facturas_con_errores > 0
ORDER BY created_at DESC;

-- Resumen de descargas por mes
SELECT 
  DATE_TRUNC('month', fecha_inicio) as mes,
  COUNT(*) as total_descargas,
  SUM(total_facturas) as facturas_descargadas,
  SUM(facturas_procesadas) as facturas_procesadas,
  SUM(facturas_con_errores) as facturas_con_errores,
  AVG(tiempo_procesamiento) as tiempo_promedio
FROM descargas
WHERE estado = 'COMPLETADO'
GROUP BY DATE_TRUNC('month', fecha_inicio)
ORDER BY mes DESC;

-- =====================================================
-- 5. FACTURAS
-- =====================================================

-- Ver todas las facturas con información completa
SELECT * FROM v_facturas_detalle
ORDER BY fecha_emision DESC
LIMIT 50;

-- Ver facturas de un proveedor específico
SELECT 
  f.numero_factura,
  f.cufe,
  f.fecha_emision,
  f.tipo_documento,
  f.procesada,
  f.fecha_procesamiento,
  p.nombre as proveedor
FROM facturas f
JOIN proveedores p ON f.proveedor_id = p.id
WHERE p.id = 'proveedor-001'
  AND f.deleted_at IS NULL
ORDER BY f.fecha_emision DESC;

-- Facturas pendientes de contabilizar
SELECT * FROM v_facturas_pendientes_contabilizar
ORDER BY fecha_emision;

-- Facturas procesadas en un rango de fechas
SELECT 
  f.numero_factura,
  f.cufe,
  f.fecha_emision,
  f.fecha_procesamiento,
  p.nombre as proveedor,
  COUNT(rc.id) as redistribuciones
FROM facturas f
JOIN proveedores p ON f.proveedor_id = p.id
LEFT JOIN redistribucion_contable rc ON f.id = rc.factura_id
WHERE f.procesada = true
  AND f.fecha_procesamiento BETWEEN '2026-02-01' AND '2026-02-28'
  AND f.deleted_at IS NULL
GROUP BY f.id, f.numero_factura, f.cufe, f.fecha_emision, f.fecha_procesamiento, p.nombre
ORDER BY f.fecha_procesamiento DESC;

-- Facturas por tipo de documento
SELECT 
  tipo_documento,
  COUNT(*) as cantidad,
  COUNT(CASE WHEN procesada THEN 1 END) as procesadas,
  COUNT(CASE WHEN NOT procesada THEN 1 END) as pendientes
FROM facturas
WHERE deleted_at IS NULL
GROUP BY tipo_documento
ORDER BY cantidad DESC;

-- Facturas sin archivo XML
SELECT 
  f.numero_factura,
  f.cufe,
  f.fecha_emision,
  p.nombre as proveedor,
  f.ruta_archivo
FROM facturas f
JOIN proveedores p ON f.proveedor_id = p.id
WHERE f.ruta_archivo IS NULL
  AND f.deleted_at IS NULL
ORDER BY f.fecha_emision DESC;

-- =====================================================
-- 6. REDISTRIBUCIONES CONTABLES
-- =====================================================

-- Ver todas las redistribuciones con detalle completo
SELECT * FROM v_redistribuciones_detalle
ORDER BY fecha_redistribucion DESC
LIMIT 50;

-- Ver redistribuciones de una factura específica
SELECT 
  rc.valor,
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  rc.es_sugerida,
  rc.aprobado,
  rc.aprobado_por,
  rc.observaciones
FROM redistribucion_contable rc
JOIN cuentas_contables cc ON rc.cuenta_contable_id = cc.id
WHERE rc.factura_id = 'factura-001'
ORDER BY rc.created_at;

-- Redistribuciones pendientes de aprobación
SELECT 
  f.numero_factura,
  f.cufe,
  p.nombre as proveedor,
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  rc.valor,
  rc.es_sugerida,
  rc.fecha_redistribucion,
  rc.observaciones
FROM redistribucion_contable rc
JOIN facturas f ON rc.factura_id = f.id
JOIN proveedores p ON rc.proveedor_id = p.id
JOIN cuentas_contables cc ON rc.cuenta_contable_id = cc.id
WHERE rc.aprobado = false
  AND f.deleted_at IS NULL
ORDER BY rc.fecha_redistribucion DESC;

-- Redistribuciones sugeridas automáticamente vs manuales
SELECT 
  es_sugerida,
  COUNT(*) as cantidad,
  SUM(valor) as valor_total,
  COUNT(CASE WHEN aprobado THEN 1 END) as aprobadas,
  COUNT(CASE WHEN NOT aprobado THEN 1 END) as pendientes
FROM redistribucion_contable
GROUP BY es_sugerida;

-- Redistribuciones por usuario aprobador
SELECT 
  aprobado_por,
  COUNT(*) as redistribuciones_aprobadas,
  SUM(valor) as valor_total_aprobado
FROM redistribucion_contable
WHERE aprobado = true
  AND aprobado_por IS NOT NULL
GROUP BY aprobado_por
ORDER BY redistribuciones_aprobadas DESC;

-- =====================================================
-- 7. REPORTES Y ANÁLISIS
-- =====================================================

-- Balance por cuenta contable
SELECT * FROM v_balance_por_cuenta
WHERE cliente_id = 'cliente-001'
ORDER BY total_valor DESC;

-- Reporte de gastos por proveedor
SELECT 
  p.nit,
  p.nombre as proveedor,
  COUNT(DISTINCT f.id) as num_facturas,
  COUNT(rc.id) as num_redistribuciones,
  SUM(rc.valor) as total_valor,
  SUM(CASE WHEN rc.aprobado THEN rc.valor ELSE 0 END) as valor_aprobado
FROM proveedores p
LEFT JOIN facturas f ON p.id = f.proveedor_id AND f.deleted_at IS NULL
LEFT JOIN redistribucion_contable rc ON f.id = rc.factura_id
WHERE p.deleted_at IS NULL
GROUP BY p.id, p.nit, p.nombre
HAVING COUNT(f.id) > 0
ORDER BY total_valor DESC;

-- Reporte de gastos por tipo de cuenta
SELECT 
  cc.tipo_cuenta,
  COUNT(DISTINCT cc.id) as num_cuentas,
  COUNT(DISTINCT rc.factura_id) as num_facturas,
  SUM(rc.valor) as total_valor
FROM cuentas_contables cc
LEFT JOIN redistribucion_contable rc ON cc.id = rc.cuenta_contable_id
WHERE cc.cliente_id = 'cliente-001'
  AND cc.deleted_at IS NULL
  AND rc.aprobado = true
GROUP BY cc.tipo_cuenta
ORDER BY total_valor DESC;

-- Reporte mensual de facturas recibidas
SELECT 
  DATE_TRUNC('month', f.fecha_emision) as mes,
  COUNT(*) as total_facturas,
  COUNT(CASE WHEN f.procesada THEN 1 END) as procesadas,
  COUNT(CASE WHEN NOT f.procesada THEN 1 END) as pendientes,
  COUNT(DISTINCT f.proveedor_id) as proveedores_unicos
FROM facturas f
WHERE f.deleted_at IS NULL
GROUP BY DATE_TRUNC('month', f.fecha_emision)
ORDER BY mes DESC;

-- Cuentas más utilizadas
SELECT 
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  cc.tipo_cuenta,
  COUNT(DISTINCT rc.factura_id) as num_facturas,
  COUNT(rc.id) as num_redistribuciones,
  SUM(rc.valor) as valor_total
FROM cuentas_contables cc
JOIN redistribucion_contable rc ON cc.id = rc.cuenta_contable_id
WHERE cc.cliente_id = 'cliente-001'
  AND cc.deleted_at IS NULL
  AND rc.aprobado = true
GROUP BY cc.id, cc.codigo_cuenta, cc.nombre_cuenta, cc.tipo_cuenta
ORDER BY num_facturas DESC, valor_total DESC
LIMIT 20;

-- Análisis de tiempo de procesamiento de facturas
SELECT 
  f.numero_factura,
  f.cufe,
  f.fecha_emision,
  f.fecha_procesamiento,
  EXTRACT(DAY FROM (f.fecha_procesamiento - f.fecha_emision)) as dias_para_procesar,
  p.nombre as proveedor
FROM facturas f
JOIN proveedores p ON f.proveedor_id = p.id
WHERE f.procesada = true
  AND f.fecha_procesamiento IS NOT NULL
  AND f.deleted_at IS NULL
ORDER BY dias_para_procesar DESC
LIMIT 20;

-- =====================================================
-- 8. CONSULTAS DE VALIDACIÓN Y AUDITORIA
-- =====================================================

-- Facturas sin redistribuciones contables
SELECT 
  f.numero_factura,
  f.cufe,
  f.fecha_emision,
  f.procesada,
  p.nombre as proveedor
FROM facturas f
JOIN proveedores p ON f.proveedor_id = p.id
LEFT JOIN redistribucion_contable rc ON f.id = rc.factura_id
WHERE rc.id IS NULL
  AND f.deleted_at IS NULL
ORDER BY f.fecha_emision DESC;

-- Cuentas contables inactivas con movimientos
SELECT 
  cc.codigo_cuenta,
  cc.nombre_cuenta,
  cc.activa,
  COUNT(rc.id) as movimientos
FROM cuentas_contables cc
LEFT JOIN redistribucion_contable rc ON cc.id = rc.cuenta_contable_id
WHERE cc.activa = false
  AND cc.deleted_at IS NULL
GROUP BY cc.id, cc.codigo_cuenta, cc.nombre_cuenta, cc.activa
HAVING COUNT(rc.id) > 0;

-- Verificar integridad: facturas procesadas sin todas las redistribuciones aprobadas
SELECT 
  f.numero_factura,
  f.cufe,
  f.procesada,
  COUNT(rc.id) as total_redistribuciones,
  COUNT(CASE WHEN rc.aprobado THEN 1 END) as redistribuciones_aprobadas
FROM facturas f
LEFT JOIN redistribucion_contable rc ON f.id = rc.factura_id
WHERE f.procesada = true
  AND f.deleted_at IS NULL
GROUP BY f.id, f.numero_factura, f.cufe, f.procesada
HAVING COUNT(CASE WHEN NOT rc.aprobado THEN 1 END) > 0;

-- CUFEs duplicados (no debería haber ninguno)
SELECT 
  cufe,
  COUNT(*) as veces_usado
FROM facturas
WHERE cufe IS NOT NULL
  AND deleted_at IS NULL
GROUP BY cufe
HAVING COUNT(*) > 1;

-- =====================================================
-- 9. CONSULTAS DE MANTENIMIENTO
-- =====================================================

-- Contar registros por tabla
SELECT 'clientes' as tabla, COUNT(*) as total FROM clientes WHERE deleted_at IS NULL
UNION ALL
SELECT 'proveedores', COUNT(*) FROM proveedores WHERE deleted_at IS NULL
UNION ALL
SELECT 'cuentas_contables', COUNT(*) FROM cuentas_contables WHERE deleted_at IS NULL
UNION ALL
SELECT 'proveedor_por_cuenta_contable', COUNT(*) FROM proveedor_por_cuenta_contable
UNION ALL
SELECT 'descargas', COUNT(*) FROM descargas
UNION ALL
SELECT 'facturas', COUNT(*) FROM facturas WHERE deleted_at IS NULL
UNION ALL
SELECT 'redistribucion_contable', COUNT(*) FROM redistribucion_contable;

-- Ver tamaño de las tablas
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size,
  pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY size_bytes DESC;

-- Ver índices de una tabla específica
SELECT 
  indexname,
  indexdef
FROM pg_indexes
WHERE tablename = 'facturas'
ORDER BY indexname;

-- Estadísticas de uso de índices
SELECT 
  schemaname,
  tablename,
  indexname,
  idx_scan as index_scans,
  idx_tup_read as tuples_read,
  idx_tup_fetch as tuples_fetched
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- =====================================================
-- 10. CONSULTAS AVANZADAS
-- =====================================================

-- Balance general simplificado por tipo de cuenta
WITH movimientos AS (
  SELECT 
    cc.tipo_cuenta,
    cc.naturaleza_cuenta,
    rc.valor
  FROM redistribucion_contable rc
  JOIN cuentas_contables cc ON rc.cuenta_contable_id = cc.id
  WHERE rc.aprobado = true
    AND cc.cliente_id = 'cliente-001'
)
SELECT 
  tipo_cuenta,
  naturaleza_cuenta,
  SUM(valor) as total,
  COUNT(*) as num_movimientos
FROM movimientos
GROUP BY tipo_cuenta, naturaleza_cuenta
ORDER BY tipo_cuenta, naturaleza_cuenta;

-- Top 10 proveedores por volumen de facturas
SELECT 
  p.nit,
  p.nombre,
  COUNT(DISTINCT f.id) as total_facturas,
  MIN(f.fecha_emision) as primera_factura,
  MAX(f.fecha_emision) as ultima_factura,
  SUM(rc.valor) as valor_total_contabilizado
FROM proveedores p
JOIN facturas f ON p.id = f.proveedor_id
LEFT JOIN redistribucion_contable rc ON f.id = rc.factura_id AND rc.aprobado = true
WHERE p.deleted_at IS NULL
  AND f.deleted_at IS NULL
GROUP BY p.id, p.nit, p.nombre
ORDER BY total_facturas DESC
LIMIT 10;

-- Análisis de redistribuciones: sugeridas vs aprobadas
WITH stats AS (
  SELECT 
    es_sugerida,
    aprobado,
    COUNT(*) as cantidad
  FROM redistribucion_contable
  GROUP BY es_sugerida, aprobado
)
SELECT 
  CASE WHEN es_sugerida THEN 'Sugerida' ELSE 'Manual' END as tipo,
  CASE WHEN aprobado THEN 'Aprobada' ELSE 'Pendiente' END as estado,
  cantidad
FROM stats
ORDER BY tipo, estado;
