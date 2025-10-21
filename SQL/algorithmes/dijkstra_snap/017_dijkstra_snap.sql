-- 017_dijkstra_snap.sql
-- Calcule un itinéraire entre deux points géographiques (lat/lon)
-- en utilisant le snapping vers les nœuds du graphe

CREATE OR REPLACE FUNCTION dijkstra_snap(
    lat1 DOUBLE PRECISION,
    lon1 DOUBLE PRECISION,
    lat2 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION
)
RETURNS JSON AS $$
DECLARE
    start_id BIGINT;
    end_id BIGINT;
    result JSON;
BEGIN
    start_id := snap_to_nearest_node(lat1, lon1);
    end_id := snap_to_nearest_node(lat2, lon2);

    SELECT json_build_object(
        'type', 'FeatureCollection',
        'features', json_agg(
            json_build_object(
                'type', 'Feature',
                'geometry', ST_AsGeoJSON(ST_Transform(r.geom, 4326))::json,
                'properties', json_build_object(
                    'edge', d.edge,
                    'cost', d.cost,
                    'seq', d.seq
                )
            )
        )
    )
    INTO result
    FROM pgr_dijkstra(
        'SELECT fid AS id, source, target, cost, reverse_cost FROM routes_v1',
        start_id, end_id, true
    ) AS d
    JOIN routes_v1 AS r
        ON d.edge = r.fid
    WHERE d.edge <> -1;

    RETURN result;
END;
$$ LANGUAGE plpgsql;