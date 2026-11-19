# MAI Image 2.7 API: cURL quickstart

```bash
export POYO_API_KEY="your-api-key"
export POYO_BASE_URL="https://api.poyo.ai"
```

## Text-to-image

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
  "model": "mai-image-2.7",
  "input": {
    "prompt": "Product photo of a mint-green ceramic table lamp with a linen shade on a walnut side table, next to a stack of two books and a small succulent in a white pot, plain off-white wall, soft daylight from the left.",
    "size": "3:2",
    "resolution": "1K"
  }
}'
```

Set `resolution` to `2K` for about 4 megapixels, for example 2720×1536 at `16:9`.

## Edit one image

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/mai-image-2.7-image-edit.json
```

The prompt quotes the current and the new text, then says what to keep. Without `size`, the output follows the reference image's aspect ratio at about 1 megapixel.

## Combine up to 5 reference images

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/mai-image-2.7-multi-reference.json
```

The prompt names each input by order: image 1 is the sneaker, image 2 the boards, image 3 the color swatch, and image 4 the pier.

## Transparent background

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
  "model": "mai-image-2.7",
  "input": {
    "prompt": "A frosted glass perfume bottle with a brushed gold cap, front three-quarter view, studio product shot with soft reflections, product only.",
    "size": "1:1",
    "resolution": "1K",
    "background": "transparent",
    "output_format": "png"
  }
}'
```

Use `output_format` `png` or `webp` for an alpha channel.

## Custom size

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d @payloads/mai-image-2.7-custom-size.json
```

`3840x1088` is returned at exactly 3840×1088. Custom sizes use both sides divisible by 16, each side at least 768, and at most 4,194,304 pixels.

## MAI Image 2.7 Flash

```bash
curl -X POST "$POYO_BASE_URL/api/generate/submit" \
  -H "Authorization: Bearer $POYO_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
  "model": "mai-image-2.7-flash",
  "input": {
    "prompt": "An empty Mediterranean seaside pier at golden hour, wide shot.",
    "size": "1:1",
    "resolution": "1K"
  }
}'
```

Flash takes the same fields as `mai-image-2.7`, so every payload in this repository also runs after changing `model`.

## Check status

Save `data.task_id` from the submit response, then poll:

```bash
curl "$POYO_BASE_URL/api/generate/status/<task_id>" \
  -H "Authorization: Bearer $POYO_API_KEY"
```

When `data.status` is `finished`, the image URL is in `data.files[0].file_url`. For production, add a public HTTPS `callback_url` to the top-level request and make the receiver idempotent.

See the [full README](../README.md) and [production notes](../docs/production-notes.md).
