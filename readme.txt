това прави 3 инстанции в AWS инсталира им nginx и ги пуска с къстъм index.html

трябва да имате ключ, който да поставите в текущата папка - например terraform-key.pem
и да промените името на ключа във v-instance-key в terraform.tfvars на terraform-key

трябва да имате и комплект access_key и secret_key за AWS и да ги поставите в terraform.tfvars
