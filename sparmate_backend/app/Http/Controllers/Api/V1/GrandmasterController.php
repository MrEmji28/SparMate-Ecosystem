<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\Grandmaster;
use Illuminate\Http\JsonResponse;

class GrandmasterController extends Controller
{
    /**
     * List all Grandmaster AI personas (GM Selection Screen).
     */
    public function index(): JsonResponse
    {
        $grandmasters = Grandmaster::orderBy('sort_order')->get();

        return response()->json([
            'grandmasters' => $grandmasters,
        ]);
    }

    /**
     * Show a single Grandmaster profile (Sparring Screen header).
     */
    public function show(Grandmaster $grandmaster): JsonResponse
    {
        return response()->json([
            'grandmaster' => $grandmaster,
        ]);
    }
}
