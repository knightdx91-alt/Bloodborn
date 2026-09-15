using System.Collections.Generic;

namespace Marrowmark.Sim.Net
{
    /// <summary>
    /// A one-way link with a delay. Deterministic on purpose: the point
    /// of a spike is to be able to re-run the exact fight at 0ms, 100ms
    /// and 400ms and compare, which a real socket cannot give you.
    ///
    /// Jitter is supplied by the caller rather than generated here, so a
    /// failing case can be replayed exactly.
    /// </summary>
    public sealed class Link<T>
    {
        private readonly struct Packet
        {
            public readonly T Payload;
            public readonly float ArrivesAt;
            public Packet(T payload, float arrivesAt)
            {
                Payload = payload;
                ArrivesAt = arrivesAt;
            }
        }

        private readonly List<Packet> _inFlight = new List<Packet>();

        /// <summary>One-way delay in seconds. Half the round trip.</summary>
        public float DelaySeconds;

        public Link(float delaySeconds) => DelaySeconds = delaySeconds;

        public void Send(T payload, float sentAt, float extraDelay = 0f)
            => _inFlight.Add(new Packet(payload, sentAt + DelaySeconds + extraDelay));

        /// <summary>Everything that has arrived by now, in arrival order,
        /// removed from the link.</summary>
        public List<T> Receive(float now)
        {
            var arrived = new List<T>();
            for (var i = _inFlight.Count - 1; i >= 0; i--)
            {
                if (_inFlight[i].ArrivesAt > now) continue;
                arrived.Add(_inFlight[i].Payload);
                _inFlight.RemoveAt(i);
            }
            // RemoveAt walked backwards, so put them back in arrival order.
            arrived.Reverse();
            return arrived;
        }

        public int InFlight => _inFlight.Count;
    }
}
