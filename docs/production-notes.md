# MAI Image 2.7 API production notes

## Confirmed contract

- Endpoint: `POST /api/generate/submit`
- Model IDs: `mai-image-2.7`, `mai-image-2.7-flash` (same request fields)
- Authentication: `Authorization: Bearer <POYO_API_KEY>`
- Status: `GET /api/generate/status/{task_id}`; the image URL is in `data.files[0].file_url`

## Input limits

| Field | Requirement | Constraint |
| --- | --- | --- |
| prompt | required | 1–32,000 characters with non-whitespace text; exact on-image text in quotes. |
| image_urls | optional | Array of 1–5 public HTTP(S) URLs; JPEG, PNG, or WebP; used at up to about 1 megapixel. |
| size | optional | 1:1, 4:3, 3:4, 3:2, 2:3, 16:9, 9:16, or WIDTHxHEIGHT; text-to-image default 1:1. |
| resolution | optional | 1K (default, about 1 megapixel) or 2K (about 4 megapixels); applies to aspect-ratio sizes. |
| background | optional | opaque (default) or transparent; transparent output uses png or webp. |
| output_format | optional | png (default), jpeg, or webp. |

Custom sizes use both sides divisible by 16, each side at least 768, and at most 4,194,304 pixels in total, and are used exactly as given. With `image_urls` and no `size`, the output follows the first reference image's aspect ratio at about 1 megapixel. Each request returns one image.

## Billing

- Token rates in credits per 1M tokens (text input / reference image input / output): 1,000 / 1,600 / 6,800 for `mai-image-2.7`, and 350 / 500 / 2,000 for `mai-image-2.7-flash`. 1 credit = $0.005.
- Output tokens = width × height / 1024; each reference image adds up to 1,024 tokens; text tokens = UTF-8 bytes / 4, rounded up.
- A maximum is reserved at submission and the final charge follows the actual tokens, never above the reserve. Failed tasks are not charged.

## Operational checklist

- Keep API keys in a server-side secret manager.
- Validate prompt length, reference count, and custom sizes before calling the API.
- Host reference images on public URLs that open without login or signed headers.
- Persist `data.task_id` immediately after submission.
- Use five-second polling only for development; prefer `callback_url` in production.
- Make webhook processing idempotent and reconcile status before fulfilling an order.
- Copy output images to durable storage after the task finishes.
- Recheck the live model page before hard-coding prices.

## Failure handling

Treat non-2xx HTTP responses and non-success API `code` values as errors. Parameter errors return HTTP 200 with `code: 400` in the body. Preserve the HTTP status, API code, and a redacted response body for debugging.

Schema: [MAI Image 2.7](https://docs.poyo.ai/api-manual/image-series/mai-image-2-7?utm_source=github&utm_medium=readme&utm_campaign=mai-image-2-7-api) and [MAI Image 2.7 Flash](https://docs.poyo.ai/api-manual/image-series/mai-image-2-7-flash?utm_source=github&utm_medium=readme&utm_campaign=mai-image-2-7-api) API references.
