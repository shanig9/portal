const FIELDS = 'id,owner_uid,author,caption,type,url,public_id,thumbnail_url,duration,created_at';
const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

function check(result) {
  if (result.error) throw result.error;
  return result.data;
}

function fromRow(row) {
  return {
    async findByPublicId(publicId) {
      const row = check(await client.from('career_reels').select(FIELDS)
        .eq('public_id', publicId).maybeSingle());
      return row ? fromRow(row) : null;
    },
    id: row.id, ownerId: row.owner_uid, author: row.author, caption: row.caption,
    type: row.type, url: row.url, publicId: row.public_id,
    thumbnailUrl: row.thumbnail_url, duration: row.duration, createdAt: row.created_at,
  };
}

function createReelsStore(client) {
  return {
    async list({ limit, cursor }) {
      let query = client.from('career_reels').select(FIELDS)
        .order('created_at', { ascending: false }).order('id', { ascending: false });
      if (cursor) {
        if (typeof cursor !== 'string' || !UUID.test(cursor)) {
          throw Object.assign(new Error('Invalid reels cursor. Refresh the feed.'), { status: 400 });
        }
        const row = check(await client.from('career_reels').select('id,created_at')
          .eq('id', cursor).maybeSingle());
        if (!row) throw Object.assign(new Error('Reel no longer exists. Refresh the feed.'), { status: 400 });
        query = query.or(`created_at.lt.${row.created_at},and(created_at.eq.${row.created_at},id.lt.${row.id})`);
      }
      const rows = check(await query.limit(limit + 1));
      const items = rows.slice(0, limit).map(fromRow);
      return { items, nextCursor: rows.length > limit ? items.at(-1).id : null };
    },
    async add(reel) {
      check(await client.from('career_reels').insert({
        id: reel.id, owner_uid: reel.ownerId, author: reel.author, caption: reel.caption,
        type: reel.type, url: reel.url, public_id: reel.publicId,
        thumbnail_url: reel.thumbnailUrl, duration: reel.duration, created_at: reel.createdAt,
      }));
    },
  };
}

module.exports = { createReelsStore };
