INSERT INTO acl_group (name, description) VALUES ('Softclient', 'Soft Client');

INSERT INTO acl_group_permission (id_action, id_group, id_resource)
SELECT 1, (SELECT id FROM acl_group WHERE name = "Softclient"), GP.id_resource  
FROM acl_group_permission AS GP
INNER JOIN acl_group AS G
ON GP.id_group == G.id
WHERE G.name == "extension";
