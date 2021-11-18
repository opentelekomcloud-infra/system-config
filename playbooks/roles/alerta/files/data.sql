--
-- PostgreSQL database dump
--

-- Dumped from database version 11.7
-- Dumped by pg_dump version 11.7

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Data for Name: alerta_environments; Type: TABLE DATA; Schema: public; Owner: alerta
--

INSERT INTO public.alerta_environments (id, name) VALUES (1, 'Production');
INSERT INTO public.alerta_environments (id, name) VALUES (3, 'prod');
INSERT INTO public.alerta_environments (id, name) VALUES (4, 'preprod');
INSERT INTO public.alerta_environments (id, name) VALUES (5, 'CSM');
INSERT INTO public.alerta_environments (id, name) VALUES (6, 'production_eu-nl');
INSERT INTO public.alerta_environments (id, name) VALUES (8, 'prod_nl');
INSERT INTO public.alerta_environments (id, name) VALUES (2, 'production_eu-de');
INSERT INTO public.alerta_environments (id, name) VALUES (7, 'hybrid_sbb');
INSERT INTO public.alerta_environments (id, name) VALUES (9, 'hybrid_eum');
INSERT INTO public.alerta_environments (id, name) VALUES (10, 'hybrid_swiss');


--
-- Data for Name: templates; Type: TABLE DATA; Schema: public; Owner: alerta
--

INSERT INTO public.templates (template_id, template_name, template_data) VALUES (1, 'DEFAULT_TMPL', '(https://alerts.eco.tsi-dev.otc-service.com/alert/{{id}})
{% if customer %}Customer: `{{customer}}` {% endif %}
 *[{{ status.capitalize() }}] {{ environment }} {{ severity.capitalize() }}*
 {{ event }} {{ resource.capitalize() }}
{% if text %}
 ```
 {{ text }}
 ```
{% endif %}
{% if value %}
 ```
 {{ value }}
 ```
{% endif %}
{% if ''logUrl'' in attributes %}[Execution Log]({{ attributes.logUrl }}){% endif %}');
INSERT INTO public.templates (template_id, template_name, template_data) VALUES (4, 'APIMON_ORCHESTRATE', '[**APImon Alert**](https://alerts.eco.tsi-dev.otc-service.com/alert/{{id}})
{% if customer %}Customer: `{{customer}}` {% endif %}
*Status: [{{ status.capitalize() }}]*
*Environment: {{ environment }}*
*Severity: {{ severity.capitalize() }}*
{% if origin %}*Origin: {{ origin }}*{% endif %}
*Service: {{ service }}, Resource: {{ resource }} has received:*
**{{ event }}**

{% for item in history | selectattr(''change_type'', ''eq'', ''note'') %}
**Note by {{ item.user }}:** *{{item.text}}*
{% endfor %}
{% if ''logUrl'' in attributes %}[Execution Log]({{ attributes.logUrl
}}){% endif %}');
INSERT INTO public.templates (template_id, template_name, template_data) VALUES (2, 'BASE', '[**APImon Alert**](https://alerts.eco.tsi-dev.otc-service.com/alert/{{id}})
{% if customer %}Customer: `{{customer}}` {% endif %}
*Status: [{{ status.capitalize() }}]*
*Environment: {{ environment }}*
*Severity: {{ severity.capitalize() }}*
{% if origin %}*Origin: {{ origin }}*{% endif %}
*Service: {{ service }}, Resource: {{ resource }} has received:*
**{{ event }}**
{% if text is defined and text|length %}
```
{{ text }}
```
{% endif %}
{% if raw_data %}
```
{{ raw_data }}
```
{% endif %}
{% for item in history | selectattr(''change_type'', ''eq'', ''note'') %}
**Note by {{ item.user }}:** *{{item.text}}*
{% endfor %}
{% if ''logUrl'' in attributes %}[Execution Log]({{ attributes.logUrl
}}){% endif %}');
INSERT INTO public.templates (template_id, template_name, template_data) VALUES (3, 'ENDPOINT_MONITOR', '[**APImon Alert**](https://alerts.eco.tsi-dev.otc-service.com/alert/{{id}})
*Environment: {{ environment }}*
```
{{ value }}
```
{% if raw_data %}
```
{{ raw_data }}
```
{% endif %}');


--
-- Data for Name: zulip_topics; Type: TABLE DATA; Schema: public; Owner: alerta
--

INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (9, 'csm', 'Alerts-Preprod', 'csm', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (34, 'zuul_refstack', 'Alerts', 'zuul_refstack', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (35, 'zuul_refstack', 'Alerts', 'zuul_refstack', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (33, 'zuul_refstack', 'Alerts', 'zuul_refstack', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (14, 'test', 'Alerts', 'test', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (15, 'test', 'Alerts', 'test', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (13, 'test', 'Alerts', 'test', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (42, 'Alerta', 'Alerts', 'Alerta', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (41, 'Alerta', 'Alerts', 'Alerta', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (43, 'Alerta', 'Alerts', 'Alerta', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (46, 'apimon_endpoint_monitor', 'Alerts', 'apimon_endpoint_monitor', 3, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (67, 'Announcements', 'Alerts', 'Announcements', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (47, 'apimon_endpoint_monitor', 'Alerts', 'apimon_endpoint_monitor', 3, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (66, 'Announcements', 'Alerts', 'Announcements', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (65, 'Announcements', 'Alerts', 'Announcements', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (30, 'apimon_block_storage', 'Alerts', 'apimon_block_storage', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (29, 'apimon_block_storage', 'Alerts', 'apimon_block_storage', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (31, 'apimon_block_storage', 'Alerts', 'apimon_block_storage', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (32, 'apimon_block_storage', 'Alerts-Preprod', 'apimon_block_storage', 2, 4, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (21, 'apimon_cce', 'Alerts', 'apimon_cce', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (23, 'apimon_cce', 'Alerts', 'apimon_cce', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (8, 'apimon_compute', 'Alerts-Preprod', 'apimon_compute', 2, 4, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (72, 'apimon_os', 'Alerts-Preprod', 'apimon_os', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (76, 'DEFAULT_TMPL', 'Alerts', 'DEFAULT_TMPL', 1, 6, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (81, 'apimon_compute', 'Alerts', 'apimon_compute', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (82, 'apimon_cce', 'Alerts', 'apimon_cce', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (7, 'apimon_compute', 'Alerts', 'apimon_compute', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (38, 'apimon_image', 'Alerts', 'apimon_image', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (37, 'apimon_image', 'Alerts', 'apimon_image', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (39, 'apimon_image', 'Alerts', 'apimon_image', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (22, 'apimon_cce', 'Alerts', 'apimon_cce', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (25, 'grafana', 'Alerts', 'grafana', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (26, 'grafana', 'Alerts', 'grafana', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (27, 'grafana', 'Alerts', 'grafana', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (77, 'apimon_endpoint_monitor', 'Alerts-Hybrid', 'apimon_endpoint_monitor', 3, 7, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (49, 'apimon_network', 'Alerts', 'apimon_network', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (5, 'apimon_compute', 'Alerts', 'apimon_compute', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (51, 'apimon_network', 'Alerts', 'apimon_network', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (56, 'apimon_rds', 'Alerts-Preprod', 'apimon_rds', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (64, 'apimon_task_executor', 'Alerts-Preprod', 'apimon_task_executor', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (50, 'apimon_network', 'Alerts', 'apimon_network', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (78, 'apimon', 'apimon', 'apimon', 1, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (60, 'apimon_wait', 'Alerts-Preprod', 'apimon_wait', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (6, 'apimon_compute', 'Alerts', 'apimon_compute', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (54, 'apimon_rds', 'Alerts', 'apimon_rds', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (73, 'test', 'Alerts-Preprod', 'csm_tests', 2, 5, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (61, 'apimon_task_executor', 'Alerts', 'apimon_task_executor', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (55, 'apimon_rds', 'Alerts', 'apimon_rds', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (17, 'apimon_orchestrate', 'Alerts', 'apimon_orchestrate', 2, 1, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (62, 'apimon_task_executor', 'Alerts', 'apimon_task_executor', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (63, 'apimon_task_executor', 'Alerts', 'apimon_task_executor', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (20, 'apimon_orchestrate', 'Alerts-Preprod', 'apimon_orchestrate', 4, 4, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (79, 'apimon_endpoint_monitor', 'Alerts-Hybrid', 'apimon_endpoint_monitor', 3, 9, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (69, 'apimon_os', 'Alerts', 'apimon_os', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (70, 'apimon_os', 'Alerts', 'apimon_os', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (18, 'apimon_orchestrate', 'Alerts', 'apimon_orchestrate', 2, 2, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (71, 'apimon_os', 'Alerts', 'apimon_os', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (74, 'DEFAULT_TMPL', 'DEFAULT_TMPL', 'DEFAULT_TMPL', 1, 8, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (53, 'apimon_rds', 'Alerts', 'apimon_rds', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (75, 'DEFAULT_TMPL', 'DEFAULT_TMPL', 'DEFAULT_TMPL', 1, 7, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (57, 'apimon_wait', 'Alerts', 'apimon_wait', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (59, 'apimon_wait', 'Alerts', 'apimon_wait', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (58, 'apimon_wait', 'Alerts', 'apimon_wait', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (19, 'apimon_orchestrate', 'Alerts', 'apimon_orchestrate', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (1, 'DEFAULT_TMPL', NULL, NULL, 1, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (2, 'DEFAULT_TMPL', NULL, NULL, 1, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (44, 'Alerta', 'Alerts-Preprod', 'Alerta', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (68, 'Announcements', 'Alerts-Preprod', 'Announcements', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (24, 'apimon_cce', 'Alerts-Preprod', 'apimon_cce', 2, 4, true);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (40, 'apimon_image', 'Alerts-Preprod', 'apimon_image', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (52, 'apimon_network', 'Alerts-Preprod', 'apimon_network', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (3, 'DEFAULT_TMPL', 'Alerts', 'DEFAULT_TMPL', 1, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (12, 'csm', 'Alerts-Preprod', 'csm', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (28, 'grafana', 'Alerts-Preprod', 'grafana', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (16, 'test', 'Alerts-Preprod', 'test', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (36, 'zuul_refstack', 'Alerts-Preprod', 'zuul_refstack', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (4, 'DEFAULT_TMPL', 'Alerts-Preprod', 'DEFAULT', 1, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (48, 'apimon_endpoint_monitor', 'Alerts-Preprod', 'apimon_endpoint_monitor', 3, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (83, 'apimon_block_storage', 'Alerts', 'apimon_block_storage', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (80, 'apimon_dns', 'Alerts', 'apimon_dns', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (11, 'csm', 'Alerts-Preprod', 'csm', 2, 3, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (85, 'apimon_image', 'Alerts', 'apimon_image', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (86, 'apimon_block_storage', 'Alerts', 'apimon_block_storage', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (87, 'apimon_block_storage', 'Alerts-Hybrid', 'apimon_block_storage', 2, 7, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (10, 'csm', 'Alerts', 'csm', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (45, 'apimon_endpoint_monitor', 'Alerts', 'apimon_endpoint_monitor', 2, 1, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (88, 'apimon_block_storage', 'Alerts-Hybrid', 'apimon_block_storage', 2, 9, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (89, 'apimon_availability', 'Alerts-Hybrid', 'apimon_availability_zone', 2, 9, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (91, 'apimon_availability', 'Alerts', 'apimon_availability', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (92, 'apimon_availability', 'Alerts', 'apimon_availability', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (84, 'apimon_networks', 'Alerts', 'apimon_network', 2, 6, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (93, 'apimon_availability', 'Alerts-Preprod', 'apimon_availability', 2, 4, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (94, 'apimon_image', 'Alerts-Hybrid', 'apimon_image', 2, 9, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (95, 'apimon_networks', 'Alerts', 'apimon_network', 2, 2, false);
INSERT INTO public.zulip_topics (topic_id, topic_name, zulip_to, zulip_subject, template_id, environment_id, skip) VALUES (90, 'apimon_network', 'Alerts-Preprod', 'apimon_network', 2, 4, false);


--
-- Name: alerta_environments_id_seq; Type: SEQUENCE SET; Schema: public; Owner: alerta
--

SELECT pg_catalog.setval('public.alerta_environments_id_seq', 1, false);


--
-- Name: templates_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: alerta
--

SELECT pg_catalog.setval('public.templates_template_id_seq', 1, false);


--
-- Name: zulip_topics_topic_id_seq; Type: SEQUENCE SET; Schema: public; Owner: alerta
--

SELECT pg_catalog.setval('public.zulip_topics_topic_id_seq', 1, false);


--
-- PostgreSQL database dump complete
--
