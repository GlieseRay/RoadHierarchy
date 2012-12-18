BEGIN;

-- reversed order required
DROP VIEW IF EXISTS roadhierarchy_z10;
DROP VIEW IF EXISTS roadhierarchy_z11;
DROP VIEW IF EXISTS roadhierarchy_z12;
DROP VIEW IF EXISTS roadhierarchy_z13;
DROP VIEW IF EXISTS roadhierarchy_z14;
DROP VIEW IF EXISTS roadhierarchy_z15;
DROP VIEW IF EXISTS roadhierarchy;




CREATE VIEW  roadhierarchy AS
	SELECT * FROM (
		SELECT  
			(CASE	WHEN highway IN ('motorway', 'motorway_link') THEN 'highway'
				WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'
				WHEN highway IN ('primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link') THEN 'major_road'
				WHEN highway IN ('residential', 'unclassified', 'road', 'minor') THEN 'minor_road'
				WHEN highway IN ('service', 'track', 'path', 'cycleway') THEN 'path'
				WHEN highway IN ('steps', 'footpath', 'footway', 'pedestrian') THEN 'pedestrian'
				WHEN railway IN ('rail') THEN 'rail'
				WHEN railway IN ('tram', 'light_rail', 'narrow_gauge') THEN 'tram'
				WHEN railway IN ('monorail') THEN 'monorail'
				WHEN railway IN ('subway') THEN 'subway'
				ELSE NULL END
			) AS z15,
			(CASE  WHEN highway IN ('motorway', 'motorway_link') THEN 'highway'
			       WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'
			       WHEN highway IN ('primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary', 'tertiary_link') THEN 'major_road'
			       WHEN highway IN ('residential', 'unclassified', 'road', 'minor') THEN 'minor_road'
			       WHEN railway IN ('rail') THEN 'rail'
			       ELSE NULL END
			) AS z14,
			(CASE  WHEN highway IN ('motorway', 'motorway_link') THEN 'highway'
			       WHEN highway IN ('trunk', 'trunk_link') THEN 'trunk'
			       WHEN highway IN ('primary', 'primary_link', 'secondary', 'secondary_link', 'tertiary') THEN 'major_road'
			       WHEN highway IN ('residential', 'unclassified', 'road', 'minor') THEN 'minor_road'
			       WHEN railway IN ('rail') THEN 'rail'
			       ELSE NULL END
			) AS z13,
			(CASE  WHEN highway IN ('motorway', 'motorway_link') THEN 'highway'
			       WHEN highway IN ('trunk') THEN 'trunk'
			       WHEN highway IN ('primary', 'secondary') THEN 'major_road'
			       WHEN highway IN ('tertiary', 'residential', 'unclassified', 'road') THEN 'minor_road'
			       WHEN railway IN ('rail') THEN 'rail'
			       ELSE NULL END
			) AS z12,
			(CASE  WHEN highway IN ('motorway') THEN 'highway'
			       WHEN highway IN ('trunk') THEN 'trunk'
			       WHEN highway IN ('primary') THEN 'major_road'
			       WHEN highway IN ('secondary', 'tertiary') THEN 'minor_road'
			       ELSE NULL END
			) AS z11,
			(CASE  WHEN highway IN ('motorway') THEN 'highway'
			       WHEN highway IN ('trunk') THEN 'trunk'
			       WHEN highway IN ('primary') THEN 'major_road'
			       WHEN highway IN ('secondary') THEN 'minor_road'
			       ELSE NULL END
			) AS z10,
		
			(CASE   WHEN oneway IN ('yes', 'true') THEN 1
				WHEN oneway IN ('no', 'false') THEN 0
				WHEN oneway = '-1' THEN -1
				ELSE 0 END
			) AS brick_oneway,			
			(CASE 	WHEN highway LIKE '%_link' THEN 1
				ELSE 0 END
			) AS is_link,
			(CASE 	WHEN tunnel IN ('yes', 'true') THEN 1
				ELSE 0 END
			) AS is_tunnel,
			(CASE	WHEN bridge IN ('yes', 'true') THEN 1
			       ELSE 0 END
			) AS is_bridge,

			-- explicit layer is the physical layering of under- and overpasses
			(CASE WHEN layer ~ E'^-?[[:digit:]]+(\\.[[:digit:]]+)?$' THEN CAST (layer AS FLOAT)
			      ELSE 0
			      END) AS explicit_layer,

			-- implied layer is guessed based on bridges and tunnels
			(CASE WHEN tunnel in ('yes', 'true') THEN -1
			      WHEN bridge in ('yes', 'true') THEN 1
			      ELSE 0
			      END) AS implied_layer,
			
			COALESCE("highway", "railway") AS brick_kind,
			(CASE
				WHEN highway IN ('motorway') THEN 0
			    WHEN railway IN ('rail') THEN .5
			    WHEN railway IN ('tram', 'light_rail', 'narrow_guage') THEN .6
			    WHEN railway IN ('monorail') THEN .7
				WHEN highway IN ('trunk') THEN 1
				WHEN highway IN ('primary') THEN 2
				WHEN highway IN ('secondary') THEN 3
				WHEN highway IN ('tertiary') THEN 4
				WHEN highway LIKE '%_link' THEN 5
				WHEN highway IN ('residential', 'unclassified', 'road') THEN 6
				WHEN highway IN ('service', 'minor') THEN 7
				WHEN railway IN ('subway') THEN 8
				ELSE 99 END
			) AS priority,
			* 
		FROM planet_osm_line
	) AS foo;


CREATE VIEW roadhierarchy_z15 AS
	SELECT  render, 
		z15 as group0, 
		brick_kind as group1, 
		brick_oneway as oneway, 
		is_link,
		is_tunnel,
		is_bridge,
		way
	FROM (
		SELECT *, 'outline' AS render, 1 AS is_outline, NULL::integer AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy
		WHERE z15 IS NOT NULL
		UNION ALL
		SELECT *, 'casing1' AS render, NULL::integer AS is_outline, 1 AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy	
		WHERE z15 IS NOT NULL
		UNION ALL
		SELECT *, 'casing2' AS render, NULL::integer AS is_outline, 2 AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy	
		WHERE z15 IS NOT NULL
		UNION ALL
		SELECT *, 'inline1' AS render, NULL::integer AS is_outline, NULL::integer AS is_casing, 1 AS is_inline
		FROM roadhierarchy	
		WHERE z15 IS NOT NULL
		UNION ALL
		SELECT *, 'inline2' AS render, NULL::integer AS is_outline, NULL::integer AS is_casing, 2 AS is_inline
		FROM roadhierarchy
		WHERE z15 IS NOT NULL
	) AS FOO
	ORDER BY 
	    is_outline ASC NULLS LAST, 
	    explicit_layer ASC, 
	    implied_layer ASC, 
	    is_casing ASC NULLS LAST, 
	    is_inline ASC NULLS LAST,
	    priority DESC;

CREATE VIEW roadhierarchy_z14 AS
	SELECT  render, 
		z14 as group0, 
		brick_kind as group1, 
		brick_oneway as oneway, 
		is_link,
		is_tunnel,
		is_bridge,
		way
	FROM (
		SELECT *, 'outline' AS render, 1 AS is_outline, NULL::integer AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy
		WHERE z14 IS NOT NULL
		UNION ALL
		SELECT *, 'casing1' AS render, NULL::integer AS is_outline, 1 AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy	
		WHERE z14 IS NOT NULL
		UNION ALL
		SELECT *, 'casing2' AS render, NULL::integer AS is_outline, 2 AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy	
		WHERE z14 IS NOT NULL
		UNION ALL
		SELECT *, 'inline1' AS render, NULL::integer AS is_outline, NULL::integer AS is_casing, 1 AS is_inline
		FROM roadhierarchy	
		WHERE z14 IS NOT NULL
		UNION ALL
		SELECT *, 'inline2' AS render, NULL::integer AS is_outline, NULL::integer AS is_casing, 2 AS is_inline
		FROM roadhierarchy
		WHERE z14 IS NOT NULL
	) AS FOO
	ORDER BY
		is_outline ASC NULLS LAST, 
	    explicit_layer ASC, 
	    implied_layer ASC, 
	    is_casing ASC NULLS LAST, 
	    is_inline ASC NULLS LAST,
	    priority DESC;

CREATE VIEW roadhierarchy_z13 AS
	SELECT  render, 
		z13 as group0, 
		brick_kind as group1, 
		brick_oneway as oneway, 
		is_link,
		is_tunnel,
		is_bridge,
		way
	FROM (
		SELECT *, 'outline' AS render, 1 AS is_outline, NULL::integer AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy
		WHERE z13 IS NOT NULL
		UNION ALL
		SELECT *, 'casing1' AS render, NULL::integer AS is_outline, 1 AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy	
		WHERE z13 IS NOT NULL
		UNION ALL
		SELECT *, 'casing2' AS render, NULL::integer AS is_outline, 2 AS is_casing, NULL::integer AS is_inline
		FROM roadhierarchy	
		WHERE z13 IS NOT NULL
		UNION ALL
		SELECT *, 'inline1' AS render, NULL::integer AS is_outline, NULL::integer AS is_casing, 1 AS is_inline
		FROM roadhierarchy	
		WHERE z13 IS NOT NULL
		UNION ALL
		SELECT *, 'inline2' AS render, NULL::integer AS is_outline, NULL::integer AS is_casing, 2 AS is_inline
		FROM roadhierarchy
		WHERE z13 IS NOT NULL
	) AS FOO
	ORDER BY
	    is_outline ASC NULLS LAST, 
	    explicit_layer ASC, 
	    implied_layer ASC, 
	    is_casing ASC NULLS LAST, 
	    is_inline ASC NULLS LAST,
	    priority DESC;


CREATE VIEW roadhierarchy_z12 AS
	SELECT  render, 
		z12 as group0, 
		brick_kind as group1, 
		brick_oneway as oneway, 
		is_link,
		is_tunnel,
		is_bridge,
		way
	FROM (
		SELECT *, 'outline' AS render, 1 AS is_outline, NULL::integer AS is_inline
		FROM roadhierarchy
		WHERE z12 IS NOT NULL
		UNION ALL
		SELECT *, 'inline1' AS render, NULL::integer AS is_outline, 1 AS is_inline
		FROM roadhierarchy	
		WHERE z12 IS NOT NULL
		UNION ALL
		SELECT *, 'inline2' AS render, NULL::integer AS is_outline, 2 AS is_inline
		FROM roadhierarchy
		WHERE z12 IS NOT NULL
	) AS FOO
	ORDER BY 	    
	    is_outline ASC NULLS LAST, 
	    explicit_layer ASC, 
	    implied_layer ASC, 
	    is_inline ASC NULLS LAST,
	    priority DESC;


CREATE VIEW roadhierarchy_z11 AS
	SELECT  render, 
		z11 as group0, 
		brick_kind as group1, 
		brick_oneway as oneway, 
		is_link,
		is_tunnel,
		is_bridge,
		way
	FROM (
		SELECT *, 'outline' AS render, 1 AS is_outline, NULL::integer AS is_inline
		FROM roadhierarchy
		WHERE z11 IS NOT NULL
		UNION ALL
		SELECT *, 'inline1' AS render, NULL::integer AS is_outline, 1 AS is_inline
		FROM roadhierarchy	
		WHERE z11 IS NOT NULL
		UNION ALL
		SELECT *, 'inline2' AS render, NULL::integer AS is_outline, 2 AS is_inline
		FROM roadhierarchy
		WHERE z11 IS NOT NULL
	) AS FOO
	ORDER BY
	    is_outline ASC NULLS LAST, 
	    explicit_layer ASC, 
	    implied_layer ASC, 
	    is_inline ASC NULLS LAST,
	    priority DESC;


CREATE VIEW roadhierarchy_z10 AS
	SELECT  render, 
		z10 as group0, 
		brick_kind as group1, 
		brick_oneway as oneway, 
		is_link,
		is_tunnel,
		is_bridge,
		way
	FROM (
		SELECT *, 'outline' AS render, 1 AS is_outline, NULL::integer AS is_inline
		FROM roadhierarchy
		WHERE z10 IS NOT NULL
		UNION ALL
		SELECT *, 'inline1' AS render, NULL::integer AS is_outline, 1 AS is_inline
		FROM roadhierarchy	
		WHERE z10 IS NOT NULL
		UNION ALL
		SELECT *, 'inline2' AS render, NULL::integer AS is_outline, 2 AS is_inline
		FROM roadhierarchy
		WHERE z10 IS NOT NULL
	) AS FOO
	ORDER BY 
	    is_outline ASC NULLS LAST, 
	    explicit_layer ASC, 
	    implied_layer ASC, 
	    is_inline ASC NULLS LAST,
	    priority DESC;
END;
