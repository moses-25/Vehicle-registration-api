<?php

namespace App\Observers;

use App\Models\Vehicle;
use illuminate\Support\Facades\Log;

class VehicleObserver
{
    public function created(Vehicle $vehicle): void
    {
        Log::info("Vehicle registered: plate={$vehicle->plate} by user_id={$vehicle->created_by}");
    }

    public function updated(Vehicle $vehicle): void
    {
        Log::info("Vehicle updated: id={$vehicle->id} plate={$vehicle->plate}");
    }

    public function deleted(Vehicle $vehicle):void
    {
        Log::warning("Vehicle deleted: id={$vehicle->id} plate={$vehicle->plate}");
    }
}
