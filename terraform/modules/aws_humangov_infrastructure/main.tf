resource "aws_security_group" "state_ec2_sg" {
    name = "humangov-${var.state_name}-ec2-sg"
    description = "Allow traffic on ports 22 and 80"

    ingress {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    
    ingress {
        from_port   = 5000
        to_port     = 5000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    # Desativado pois não uso cloud9, utilizado para conceder acesso através do ip interno
    #  privado para a ec2 do cloud 9 acessar as ec2 provisionadas
    #  e tudo é acessível localmente. 
    # ingress {
    #     from_port   = 0
    #     to_port     = 0
    #     protocol    = "-1"
    #     security_groups = ["<INSERT_YOUR_EC2/IDE_SECURITY_GROUP_ID>"]
    # }
    
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = { Name = "humangov-${var.state_name}" }
}

resource "aws_instance" "state_ec2" {
    ami = "ami-007855ac798b5175e"
    instance_type = "t2.micro"
    key_name = "humangov-ec2-key"
    vpc_security_group_ids = [aws_security_group.state_ec2_sg.id]
    iam_instance_profile = aws_iam_instance_profile.s3_dynamodb_full_access_instance_profile.name
    tags = {
      Name = "human-gov-${var.state_name}"
    }

}

resource "aws_dynamodb_table" "state_dynamodb" {
    name = "humangov-${var.state_name}-dynamodb"
    billing_mode = "PAY_PER_REQUEST"
    hash_key = "id"

    attribute {
      name = "id"
      type = "S"
    }

    tags = {
        Name = "humangov-${var.state_name}"
    }
}

resource "random_string" "bucket_suffix" {
    length = 4
    special = false
    upper = false
    
}

resource "aws_s3_bucket" "state_s3"{
   bucket = "humangov-${var.state_name}-s3-${random_string.bucket_suffix.result}"
   tags = {
    Name = "humangov-${var.state_name}"
   }
}

# Create an IAM Role for EC2 to access S3 and DynamoDB
resource "aws_iam_role" "s3_dynamodb_full_access_role" {
    name="humangov-${var.state_name}-s3_dynamodb_full_access_role"

    assume_role_policy = <<EOF
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Action": "sts:AssumeRole",
                "Principal": {
                    "Service": "ec2.amazonaws.com"
                },
                "Effect": "Allow",
                "Sid": ""
            }
        ]
    }
    EOF

     tags= {
        Name = "humangov-${var.state_name}"
     }
}

# Attach AmazonS3FullAccess policy to the IAM Role
resource "aws_iam_role_policy_attachment" "s3_full_access_role_policy_attachment" {
    role = aws_iam_role.s3_dynamodb_full_access_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Attach Amazon DynamoDBFullAccess policy to the IAM Role
resource "aws_iam_role_policy_attachment" "dynamodb_full_access_role_policy_attachment" {
    role = aws_iam_role.s3_dynamodb_full_access_role.name
    policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

# Create an IAM Instance Profile for the EC2 instance
resource "aws_iam_instance_profile" "s3_dynamodb_full_access_instance_profile" {
    name = "humangov-${var.state_name}-s3_dynamodb_full_access_instance_profile"
    role= aws_iam_role.s3_dynamodb_full_access_role.name

    tags = {
        Name = "humangov-${var.state_name}"
    }
}


    
    

                
    
