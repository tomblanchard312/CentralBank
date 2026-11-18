const VALID_ENVIRONMENTS = ['lab', 'test', 'pilot', 'prod'];

function createConfig(envName = process.env.CENTRALBANK_ENV) {
  if (!envName || !VALID_ENVIRONMENTS.includes(envName)) {
    const message =
      `CENTRALBANK_ENV must be one of: ${VALID_ENVIRONMENTS.join(', ')}, got: ${envName || 'undefined'}`;
    const error = new Error(message);
    error.code = 'INVALID_ENVIRONMENT';
    throw error;
  }

  const environments = {
    lab: {
      storage: 'file',
      maxBatchSize: 100,
      maxRequestSize: '1mb',
      retentionDays: 30
    },
    test: {
      storage: 'memory',
      maxBatchSize: 50,
      maxRequestSize: '500kb',
      retentionDays: 1
    },
    pilot: {
      storage: 'rotating-file',
      maxBatchSize: 1000,
      maxRequestSize: '5mb',
      retentionDays: 90,
      rotationIntervalHours: 24
    },
    prod: {
      storage: 'durable',
      maxBatchSize: 5000,
      maxRequestSize: '10mb',
      retentionDays: 2555,
      rotationIntervalHours: 168
    }
  };

  const current = environments[envName];

  return {
    environment: envName,
    storageType: current.storage,
    maxBatchSize: current.maxBatchSize,
    maxRequestSize: current.maxRequestSize,
    retentionDays: current.retentionDays,
    rotationIntervalHours: current.rotationIntervalHours,
    raw: current
  };
}

function loadRuntimeConfig() {
  try {
    const config = createConfig();
    console.log(JSON.stringify({
      timestamp: new Date().toISOString(),
      severity: 'INFO',
      component: 'reconciliation-ref',
      event_type: 'environment_startup',
      environment: config.environment,
      config: config.raw
    }));
    return config;
  } catch (error) {
    console.error(JSON.stringify({
      timestamp: new Date().toISOString(),
      severity: 'ERROR',
      component: 'reconciliation-ref',
      event_type: 'invalid_environment',
      message: error.message
    }));
    process.exit(1);
  }
}

module.exports = {
  VALID_ENVIRONMENTS,
  createConfig,
  loadRuntimeConfig
};
