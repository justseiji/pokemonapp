const express = require('express');
const router = express.Router();
const AWS = require('aws-sdk');
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../.env'), override: true });

// Configure AWS with credentials from .env
AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

const ec2 = new AWS.EC2();

function getInstanceId() {
  return process.env.EC2_INSTANCE_ID || process.env.INSTANCE_ID;
}

// Middleware to check if Instance ID exists
router.use((req, res, next) => {
  if (!getInstanceId()) {
    return res.status(400).json({ message: 'EC2_INSTANCE_ID not configured in backend' });
  }
  next();
});

// GET /ec2/status
router.get('/status', (req, res) => {
  const params = { InstanceIds: [getInstanceId()] };

  ec2.describeInstances(params, (err, data) => {
    if (err) {
      console.error('DescribeInstances error:', err);
      return res.status(500).json({ message: 'Error describing instances', error: err.message });
    }

    if (data.Reservations.length > 0 && data.Reservations[0].Instances.length > 0) {
      const instance = data.Reservations[0].Instances[0];
      const state = instance.State.Name; // will be 'running', 'stopped', 'pending', etc.
      return res.json({ instance_id: getInstanceId(), state });
    } else {
      return res.status(404).json({ message: 'Instance not found' });
    }
  });
});

// POST /ec2/start
router.post('/start', (req, res) => {
  const params = { InstanceIds: [getInstanceId()] };

  ec2.startInstances(params, (err, data) => {
    if (err) {
      console.error('StartInstances error:', err);
      return res.status(500).json({ message: 'Error starting instance', error: err.message });
    }
    const startingInstances = data.StartingInstances;
    res.json({ message: 'Instance start initiated', instances: startingInstances });
  });
});

// POST /ec2/stop
router.post('/stop', (req, res) => {
  const params = { InstanceIds: [getInstanceId()] };

  ec2.stopInstances(params, (err, data) => {
    if (err) {
      console.error('StopInstances error:', err);
      return res.status(500).json({ message: 'Error stopping instance', error: err.message });
    }
    const stoppingInstances = data.StoppingInstances;
    res.json({ message: 'Instance stop initiated', instances: stoppingInstances });
  });
});

module.exports = router;
