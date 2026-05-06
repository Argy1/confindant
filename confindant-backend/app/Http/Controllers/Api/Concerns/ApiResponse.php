<?php

namespace App\Http\Controllers\Api\Concerns;

use Carbon\CarbonInterface;
use Illuminate\Database\Eloquent\Model as EloquentModel;
use Illuminate\Support\Collection;
use MongoDB\BSON\ObjectId;

trait ApiResponse
{
    protected function ok(mixed $data = null, string $message = 'OK', array $meta = [], int $status = 200)
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $this->transform($data),
            'meta' => (object) $meta,
        ], $status);
    }

    protected function fail(string $message = 'Request failed', array $errors = [], int $status = 422)
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'data' => null,
            'errors' => (object) $errors,
        ], $status);
    }

    private function transform(mixed $value): mixed
    {
        if ($value instanceof Collection) {
            return $value->map(fn ($item) => $this->transform($item))->all();
        }

        if ($value instanceof EloquentModel) {
            return $this->transform($value->toArray());
        }

        if ($value instanceof CarbonInterface) {
            return $value->toIso8601String();
        }

        if ($value instanceof ObjectId) {
            return (string) $value;
        }

        if (is_array($value)) {
            $result = [];
            foreach ($value as $key => $item) {
                $result[$key] = $this->transform($item);
            }

            if (array_key_exists('_id', $result)) {
                $result['id'] = (string) $result['_id'];
                $result['_id'] = (string) $result['_id'];
            }

            return $result;
        }

        return $value;
    }
}
