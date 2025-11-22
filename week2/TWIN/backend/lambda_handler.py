from mangum import Mangum
from server import app

# Create the Lambda handler
handler = Mangum(app)