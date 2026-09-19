<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Enum;

class UpdateVehicleRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $vehicleId = $this->route('vehicle')?->id;

        return [
            'plate' => ['sometimes', 'string', 'max:10', Rule::unique('vehicles', 'plate')->ignore($vehicleId)],
            'type' => ['sometimes', new Enum(\App\Enums\VehicleType::class)],
            'brand' => ['sometimes', 'string', 'max:50'],
            'model' => ['sometimes', 'string', 'max:50'],
            'year' => ['sometimes', 'integer', 'min:1900', 'max:'.(date('Y') + 1)],
            'color' => ['sometimes', 'string', 'max:20'],
            'owner_name' => ['sometimes', 'string', 'max:100'],
            'owner_document' => ['sometimes', 'string', 'max:30'],
        ];
    }
}
