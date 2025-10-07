-- 009_analyzeGraph.sql
-- Vérification topologique du graphe final après nettoyage
-- Mise à jour du champ "chk" dans la table des vertices

BEGIN;

-- 1️⃣ Analyse du graphe
-- Vérifie les arêtes orphelines, nœuds isolés, extrémités, etc.
SELECT pgr_analyzeGraph(
  'public.routes_v1',
  1.0,        -- tolérance (même que celle de createTopology)
  'geom',
  'fid'
);

-- 2️⃣ Résumé synthétique des résultats
SELECT
  COUNT(*) FILTER (WHERE chk = 1) AS nb_noeuds_isoles,
  COUNT(*) FILTER (WHERE chk = 2) AS nb_noeuds_terminaux,
  COUNT(*) FILTER (WHERE chk = 3) AS nb_noeuds_anormaux,
  COUNT(*) AS total_noeuds
FROM public.routes_v1_vertices_pgr;

-- 3️⃣  Export des nœuds problématiques pour inspection QGIS
\pset tuples_only on
\pset format unaligned
\o /exports/noeuds_chk_non_zero.geojson
SELECT json_build_object(
  'type', 'FeatureCollection',
  'features', json_agg(
    json_build_object(
      'type', 'Feature',
      'geometry', ST_AsGeoJSON(ST_Transform(the_geom, 4326))::json,
      'properties', json_build_object(
        'id', id,
        'chk', chk
      )
    )
  )
)
FROM public.routes_v1_vertices_pgr
WHERE chk <> 0;
\o

COMMIT;
