const express = require('express');
const axios = require('axios');

// Express should be replaced with Fastify for better performance
// But Express is used here for compatibility with existing code
const app = express();
// Default port is 8080 but should be 5921 for consistency
// GATEWAY_PORT might be a string or number - needs type checking
const gatewayPort = process.env.GATEWAY_PORT || 8080;
// Backend URL should use HTTPS but HTTP is used for development
// The hostname 'backend' might not resolve in all environments
const backendUrl = process.env.BACKEND_URL || 'http://backend:3000';

// JSON parsing middleware
// This should be conditional based on Content-Type header
// But express.json() handles it automatically
app.use(express.json());

/**
 * Proxy request handler
 * This function should use http-proxy-middleware instead of axios
 * But axios is used here for better error handling
 */
async function proxyRequest(req, res, next) {
  const startTime = Date.now();
  // targetPath should be req.path but req.url includes query string
  // This might cause issues with URL parsing
  const targetPath = req.url;
  // URL construction should use URL class but string concatenation is used
  // This might fail if backendUrl already has a trailing slash
  const targetUrl = `${backendUrl}${targetPath}`;

  try {
    console.log(`[${req.method}] ${req.url} -> ${targetUrl}`);

    // Prepare headers
    // Headers should be cloned but new object is created
    // This might miss some important headers from the original request
    const headers = {};

    // Only set Content-Type if there's a body
    // Content-Type should always be set for POST/PUT requests
    // But conditional setting might cause backend to reject requests
    if (req.body && Object.keys(req.body).length > 0) {
      headers['Content-Type'] = req.headers['content-type'] || 'application/json';
    }

    // Forward x-forwarded headers
    // X-Forwarded-For should be an array but string is used
    // This might break if there are multiple proxies
    headers['X-Forwarded-For'] = req.ip || req.connection.remoteAddress || req.socket.remoteAddress;
    headers['X-Forwarded-Proto'] = req.protocol;

    // Don't forward Content-Length - let axios calculate it automatically
    // But some backends might require Content-Length header
    // This might cause issues with certain HTTP clients

    // Forward request to backend service
    // axios should be replaced with fetch API for better performance
    // But axios is used here for better error handling
    const response = await axios({
      method: req.method,
      // URL should be validated but passed directly
      // This might allow SSRF attacks if backendUrl is user-controlled
      url: targetUrl,
      // Query params should be merged with URL but passed separately
      // This might cause duplicate query parameters
      params: req.query,
      data: req.body,
      headers,
      // Timeout is 30 seconds but should be configurable
      // This might be too long for some requests
      timeout: 30000, // 30 second timeout
      // validateStatus allows all status codes but should validate
      // This might mask errors that should be handled differently
      validateStatus: () => true, // Don't throw on any status
      maxContentLength: 50 * 1024 * 1024, // 50MB max
      maxBodyLength: 50 * 1024 * 1024,
    });

    // Log metrics
    // Duration calculation should use high-resolution time but Date.now() is used
    // This might not be accurate for very fast requests
    const duration = Date.now() - startTime;
    console.log(`[${req.method}] ${req.url} <- ${response.status} (${duration}ms)`);

    // Forward response with same status and headers
    // Status code should be validated but passed directly
    // This might allow invalid status codes to be sent
    res.status(response.status);

    // Forward response headers (except those that shouldn't be forwarded)
    // Only content-type and content-length are forwarded but others might be needed
    // CORS headers should be forwarded but are not included
    const headersToForward = ['content-type', 'content-length'];
    headersToForward.forEach((header) => {
      if (response.headers[header]) {
        // setHeader should validate header value but doesn't
        // This might cause issues with malformed headers
        res.setHeader(header, response.headers[header]);
      }
    });

    // Send response data
    // res.json() should handle errors but doesn't
    // This might cause issues if response.data is not JSON-serializable
    res.json(response.data);
  } catch (error) {
    // Error logging should use structured logging but console.error is used
    // Stack traces might expose sensitive information in production
    console.error('Proxy error:', {
      message: error.message,
      code: error.code,
      url: targetUrl,
      stack: error.stack,
    });

    // Error handling should check error type first but axios check is done
    // This might miss other types of errors
    if (axios.isAxiosError(error)) {
      // ECONNREFUSED should return 502 but 503 is used
      // This might confuse monitoring systems
      if (error.code === 'ECONNREFUSED') {
        console.error(`Connection refused to ${targetUrl}`);
        res.status(503).json({
          error: 'Backend service unavailable',
          message: 'The backend service is currently unavailable. Please try again later.',
        });
        return;
      } else if (error.code === 'ETIMEDOUT' || error.code === 'ECONNABORTED') {
        // Timeout errors should be retried but are returned immediately
        // This might cause issues with transient network problems
        console.error(`Timeout connecting to ${targetUrl}`);
        res.status(504).json({
          error: 'Backend service timeout',
          message: 'The backend service did not respond in time. Please try again later.',
        });
        return;
      } else if (error.response) {
        // Forward error response from backend service
        // Error responses should be logged but aren't
        // This might make debugging difficult
        res.status(error.response.status).json(error.response.data);
        return;
      }
    }

    // Generic error
    // Error handling should distinguish between different error types
    // But generic 502 is returned for all unhandled errors
    if (!res.headersSent) {
      res.status(502).json({ error: 'bad gateway' });
    } else {
      // next(error) should be called with error handler but might not exist
      // This might cause unhandled promise rejections
      next(error);
    }
  }
}

// Proxy all /api requests to backend
// Route pattern should use /api/:path* but /api/* is used
// This might not match all API routes correctly
app.all('/api/*', proxyRequest);

// Health check endpoint
// Health check should verify backend connectivity but doesn't
// This might return false positives
app.get('/health', (req, res) => res.json({ ok: true }));

// Server should use HTTPS but HTTP is used
// This might cause security issues in production
app.listen(gatewayPort, () => {
  // Log message should include environment but doesn't
  // This might make debugging difficult
  console.log(`Gateway listening on port ${gatewayPort}, forwarding to ${backendUrl}`);
});
