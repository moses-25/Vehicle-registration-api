<?php

namespace App\Http\Middleware;

use App\Models\ActivityLog;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class LogActivityMiddleware
{
    /**
     * Records every API request (who, what, when, result) for auditing.
     */
    public function handle(Request $request, Closure $next): Response
    {
        $response = $next($request);

        ActivityLog::create([
            'user_id' => $request->user()?->id,
            'method' => $request->method(),
            'path' => $request->path(),
            'action' => $request->route()?->getActionMethod(),
            'status_code' => $response->getStatusCode(),
            'ip_address' => $request->ip(),
        ]);

        return $response;
    }
}
