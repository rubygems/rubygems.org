-- Registry data report for the Sustaining Package Registries Working Group
-- (rubygems/maintainers#167). Run it with script/registry-report, which
-- sets :previous_at when an earlier dump's gem_downloads were loaded.
--
-- Uses only the tables in the public dump. All timestamps are UTC.

\pset footer off
\pset null 'n/a'

-- The dump has no export timestamp, so the newest push stands in for it.
SELECT date_trunc('second', max(created_at)) AS snapshot_at,
       date_trunc('second', max(created_at)) - interval '12 months' AS window_start,
       date_trunc('month', max(created_at)) - interval '12 months' AS first_month,
       date_trunc('month', max(created_at)) AS end_month
FROM versions
\gset

\echo '# RubyGems.org registry data report'
\echo
\echo 'Snapshot:' :snapshot_at 'UTC (newest version push in the dump)'
\echo 'Past 12 months: after' :window_start 'UTC'
\if :{?previous_at}
\echo 'Earlier dump for download counts:' :previous_at 'UTC'
\endif

\echo
\echo '## 1. Scale'
\echo
SELECT metric, value FROM (VALUES
  (1, 'Gems', (SELECT count(*) FROM rubygems WHERE indexed)),
  (2, 'Versions', (SELECT count(*) FROM versions WHERE indexed)),
  (3, 'Releases', (SELECT count(*) FROM (SELECT DISTINCT rubygem_id, number FROM versions WHERE indexed) AS releases)),
  (4, 'Active publishers (accounts)', (SELECT count(DISTINCT pusher_id) FROM versions WHERE indexed AND created_at > :'window_start')),
  (5, 'Gems pushed with trusted publishing', (SELECT count(DISTINCT rubygem_id) FROM versions WHERE indexed AND created_at > :'window_start' AND pusher_id IS NULL AND pusher_api_key_id IS NOT NULL)),
  (6, 'Owners', NULL)
) AS scale(position, metric, value)
ORDER BY position;

\echo '- Gems: gems with at least one version that is not yanked (the count on rubygems.org/stats).'
\echo '- Versions: versions that are not yanked. Each platform build of a version number counts separately.'
\echo '- Releases: distinct (gem, version number) pairs that are not yanked, so platform builds count once.'
\echo '- Active publishers: distinct user accounts that pushed at least one version in the past 12 months that is not yanked.'
\echo '- Gems pushed with trusted publishing: gems with a version pushed in the past 12 months, not yanked, that has no pushing user. Trusted publishing pushes are not tied to an account, so they are not in the active publishers count.'
\echo '- Owners: n/a. The public dump has no ownership or user tables.'

\echo
\echo '## 2. Recent activity'
\echo
SELECT to_char(date_trunc('month', created_at), 'YYYY-MM') AS month,
       count(DISTINCT (rubygem_id, number)) AS releases,
       count(DISTINCT (rubygem_id, number)) FILTER (WHERE indexed) AS releases_not_yanked,
       count(DISTINCT rubygem_id) FILTER (WHERE created_at = first_push) AS new_gems,
       count(DISTINCT rubygem_id) FILTER (WHERE created_at = first_push AND gem_indexed) AS new_gems_not_yanked
FROM (
  SELECT versions.rubygem_id, versions.number, versions.created_at, versions.indexed,
         rubygems.indexed AS gem_indexed,
         min(versions.created_at) OVER (PARTITION BY versions.rubygem_id) AS first_push
  FROM versions
  JOIN rubygems ON rubygems.id = versions.rubygem_id
) AS pushes
WHERE created_at >= :'first_month' AND created_at < :'end_month'
GROUP BY 1
ORDER BY 1;

\echo '- The 12 most recent complete calendar months before the snapshot.'
\echo '- releases: distinct (gem, version number) pairs pushed in the month, so platform builds of one version count once. releases_not_yanked leaves out releases yanked since.'
\echo '- new_gems: gems whose first version was pushed in the month. new_gems_not_yanked leaves out gems with every version yanked since.'
\echo '- A large gap between a count and its _not_yanked count means many of that month''s pushes were yanked later.'
\echo '- Monthly downloads: n/a. The public dump only stores all-time download totals, and older dumps move to GLACIER storage after about 8 weeks, so 12 months of monthly downloads cannot come from public dumps.'
\echo
SELECT 'All-time downloads' AS metric,
       (SELECT count FROM gem_downloads WHERE rubygem_id = 0 AND version_id = 0) AS value
\if :{?previous_at}
UNION ALL
SELECT 'Downloads between dumps (' || round(extract(epoch FROM :'snapshot_at'::timestamp - :'previous_at'::timestamp) / 86400, 1) || ' days)',
       (SELECT count FROM gem_downloads WHERE rubygem_id = 0 AND version_id = 0)
       - (SELECT count FROM previous_gem_downloads WHERE rubygem_id = 0 AND version_id = 0)
\endif
;

\echo '- All-time downloads: the registry-wide download total at the snapshot.'
\if :{?previous_at}
\echo '- Downloads between dumps: the change in that total since the earlier dump.'
\endif

\echo
\echo '## 3. Maintenance'
\echo
WITH gems AS (
  SELECT EXISTS (SELECT 1 FROM versions WHERE rubygem_id = rubygems.id AND indexed AND created_at > :'window_start') AS released,
\if :{?previous_at}
         -- 1: under 100 downloads, 2: 100 to 999, ... 5: 100,000 or more.
         least(greatest(floor(log(greatest(coalesce(current.count, 0) - coalesce(previous.count, 0), 1))), 1), 5) AS band
  FROM rubygems
  LEFT JOIN gem_downloads current ON current.rubygem_id = rubygems.id AND current.version_id = 0
  LEFT JOIN previous_gem_downloads previous ON previous.rubygem_id = rubygems.id AND previous.version_id = 0
\else
         NULL::numeric AS band
  FROM rubygems
\endif
  WHERE indexed
)
SELECT CASE WHEN GROUPING(band) = 1 THEN 'All gems'
            WHEN band = 1 THEN 'Under 100 downloads'
            WHEN band = 5 THEN '100,000 or more downloads'
            ELSE to_char(10 ^ band, 'FM999,999') || ' to ' || to_char(10 ^ (band + 1) - 1, 'FM999,999') || ' downloads'
       END AS gems,
       count(*) AS total,
       count(*) FILTER (WHERE released) AS with_release,
       count(*) FILTER (WHERE NOT released) AS without_release,
       round(100.0 * count(*) FILTER (WHERE released) / count(*), 1) AS pct_with_release
FROM gems
GROUP BY GROUPING SETS ((band), ())
-- Without an earlier dump, band is always NULL; keep only the All gems row.
HAVING band IS NOT NULL OR GROUPING(band) = 1
ORDER BY GROUPING(band), band;

\echo '- Gems: as in Scale. with_release: the gem has a version pushed in the past 12 months that is not yanked.'
\if :{?previous_at}
\echo '- Download bands: how much the gem''s all-time download total grew between the earlier dump and the snapshot. This is the "recent download activity" measure.'
\echo '  Nearly every gem gets some downloads in any few weeks (mirrors and scanners fetch everything), so pick a band as the cut-off for "recently downloaded" rather than "any downloads".'
\else
\echo '- Recent download activity: n/a. Pass an earlier dump with -P to split gems by downloads between the two dumps.'
\endif
