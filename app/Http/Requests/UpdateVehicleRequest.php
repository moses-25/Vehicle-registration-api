<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Role;
use Illuminate\Validation\Rules\Enum;

class UpdateVehicleRequest extends FormRequest
{
    /**
     * Determine if the user is authorized to make this request.
     */
    public function authorize(): bool
    {
        return true;
    }

    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'plate' => ['sometimes', 'string', 'max:10', Rule::unique('vehicles', 'plate')->ignore($vehicleId)],
            'type' => ['sometimes', new Enum(\App\Enums\VehicleType::class)],
            'brand' => ['sometimes', 'string', 'max:50'],
            'model' => ['sometimes', 'string', 'max:50'],
            'year' => ['sometimes', 'integer', 'min:1900', 'max:'.(date('y') + 1)],
            'color' => ['sometimes', 'string', 'max:20'],
            'owner_name' => ['sometimes', 'string', 'max:100'],
            'owner_document' => ['sometimes', 'string', 'max:30'],
        ];
    }
}
