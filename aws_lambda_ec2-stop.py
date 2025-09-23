import boto3

ec2 = boto3.resource('ec2')

def lambda_handler(event, context):    
    filter = [
        {
            'Name': 'instance-state-name', 
            'Values': [ 'running' ]
        }
    ]
        
    instances = ec2.instances.filter(Filters=filter)
    
    for i in instances:
        for tag in i.tags:
            if tag['Key'] == 'Name':
                instanceName = tag['Value']
                i.stop()
                print('Stopping instances:', str(i), instanceName)
        
    return 'Success'
