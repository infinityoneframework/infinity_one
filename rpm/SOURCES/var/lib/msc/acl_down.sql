DELETE FROM acl_group_permission
WHERE id_group = (
  SELECT G.id
  FROM acl_group AS G
  WHERE G.name = "Softclient"
);

DELETE FROM acl_user
WHERE id IN (
  SELECT M.id_user
  FROM acl_group AS G
  INNER JOIN acl_membership AS M
  ON M.id_group = G.id
  WHERE G.name = "Softclient"
);

DELETE FROM acl_group WHERE name = "Softclient";
