# ============================================================
# moved.tf — Historique des renommages de ressources Terraform
# ============================================================
# Ces blocs disent à Terraform : "cette ressource n'a pas été
# détruite et recréée, elle a juste été renommée dans le code."
# Sans eux, Terraform détruirait et recréerait inutilement.
# ============================================================

moved {
  from = aws_subnet.mini_chat_public_subnet
  to   = aws_subnet.public_1
}

moved {
  from = aws_subnet.mini_chat_private_subnet_1
  to   = aws_subnet.private_1
}

moved {
  from = aws_subnet.mini_chat_private_subnet_2
  to   = aws_subnet.private_2
}

moved {
  from = aws_internet_gateway.mini_chat_igw
  to   = aws_internet_gateway.igw
}

moved {
  from = aws_route_table.mini_chat_public_rt
  to   = aws_route_table.public_rt
}

moved {
  from = aws_route_table_association.mini_chat_public_rta
  to   = aws_route_table_association.public_1
}

moved {
  from = aws_security_group.mini_chat_db_sg
  to   = aws_security_group.db_sg
}

