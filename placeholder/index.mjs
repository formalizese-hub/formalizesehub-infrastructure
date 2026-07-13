// Placeholder handler — será sobreescrito por GitHub Actions CI/CD
// Este código solo existe para la creación inicial del stack SAM
export const handler = async (event) => {
    return {
        statusCode: 503,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({
            message: 'Service initializing — deployment in progress',
            timestamp: new Date().toISOString(),
        }),
    };
};

// Handler alternativo para SQS triggers (no retorna HTTP response)
export const sqsHandler = async (event) => {
    console.log('Placeholder SQS handler — awaiting CI/CD deployment');
    return { batchItemFailures: [] };
};

// Handler para consecutivo (grupo-redistribucion usa handler diferente)
export const consecutivoHandler = async (event) => {
    return {
        statusCode: 503,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
        },
        body: JSON.stringify({ message: 'Service initializing' }),
    };
};
