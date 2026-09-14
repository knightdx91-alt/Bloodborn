using System;

namespace Marrowmark.Sim.Combat
{
    /// <summary>What the enemy wants to do this tick.</summary>
    public enum TacticalIntent
    {
        /// <summary>Too far to threaten. Walk in.</summary>
        Close,

        /// <summary>In range, waiting out the gap between attacks.</summary>
        Circle,

        /// <summary>Throw the attack named in <see cref="TacticalDecision.Shape"/>.</summary>
        Attack,

        /// <summary>Committed to something already. Do not interrupt it.</summary>
        Busy,
    }

    /// <summary>One tick's decision.</summary>
    public struct TacticalDecision
    {
        public TacticalIntent Intent;
        public AttackShape Shape;
    }

    /// <summary>
    /// One enemy's choice of what to throw and when (combat.md §6,
    /// tech.md §6 Stage 1 step 5).
    ///
    /// Deliberately *not* clever. §6's whole claim is that a player learns
    /// the three shapes in the first hour by reading them, and that only
    /// happens if the enemy throws all three often enough to teach them —
    /// an opponent that picks optimally would throw quick attacks forever
    /// and teach nothing. So this cycles with a bias rather than
    /// optimising, and the interesting behaviour is meant to come from the
    /// shapes themselves.
    ///
    /// Deterministic: the caller supplies the seed, and the same seed with
    /// the same inputs always produces the same fight. combat.md §7 makes
    /// damage server-authoritative, so client and server have to be able to
    /// agree about what the enemy did.
    ///
    /// Engine-free by the same rule as everything else here: no vectors, no
    /// global clock. The caller says how far away the target is; this says
    /// what to do about it.
    /// </summary>
    public sealed class EnemyTactics
    {
        private readonly EnemyTacticsProfile _profile;
        private uint _state;
        private float _sinceLastAttack;
        private int _quickChain;

        public EnemyTactics(EnemyTacticsProfile profile, uint seed = 1)
        {
            _profile = profile;
            // Never zero: the generator below is a fixed point at zero.
            _state = seed == 0u ? 0x9E3779B9u : seed;
            _sinceLastAttack = profile.RecoverBetweenAttacksSeconds;
        }

        /// <summary>Seconds since the last attack was thrown.</summary>
        public float SinceLastAttack => _sinceLastAttack;

        /// <summary>
        /// Quick attacks thrown back to back. §6 says quick attacks chain;
        /// this is what stops them chaining forever.
        /// </summary>
        public int QuickChain => _quickChain;

        public void Tick(float deltaSeconds)
        {
            if (deltaSeconds > 0f) _sinceLastAttack += deltaSeconds;
        }

        /// <summary>
        /// Decide. <paramref name="busy"/> is the caller saying an attack
        /// is already running — the enemy is as committed to its swings as
        /// the player is to theirs.
        /// </summary>
        public TacticalDecision Decide(float distanceToTarget, Stamina stamina, bool busy)
        {
            if (stamina == null) throw new ArgumentNullException(nameof(stamina));

            if (busy)
                return new TacticalDecision { Intent = TacticalIntent.Busy };

            if (distanceToTarget > _profile.EngageRange)
                return new TacticalDecision { Intent = TacticalIntent.Close };

            if (_sinceLastAttack < _profile.RecoverBetweenAttacksSeconds)
                return new TacticalDecision { Intent = TacticalIntent.Circle };

            // The chain cap is checked here rather than inside the choice,
            // because it must not be overridden by the affordability rule
            // below. It was, and the result was an exhausted enemy jabbing
            // forever: every forced heavy got downgraded straight back to a
            // quick, chains ran to five and beyond, and a player fighting a
            // tired enemy would never be taught to parry at all.
            var capped = _quickChain >= _profile.MaxQuickChain;
            var shape = ChooseShape(distanceToTarget);

            // An enemy that cannot pay swings anyway and exhausts itself,
            // exactly as a player does (combat.md §2) — but while it has a
            // choice it should not reach for the most expensive option.
            // When the chain is capped it has no choice, and overextending
            // into a heavy it cannot afford is good: that is the punish
            // window a player is supposed to learn to wait for.
            if (!capped && shape != AttackShape.Quick
                && !stamina.CanAfford(AttackProfile.For(shape).StaminaCost))
            {
                shape = AttackShape.Quick;
            }

            return new TacticalDecision { Intent = TacticalIntent.Attack, Shape = shape };
        }

        /// <summary>Call when an attack is actually thrown.</summary>
        public void Threw(AttackShape shape)
        {
            _sinceLastAttack = 0f;
            _quickChain = shape == AttackShape.Quick ? _quickChain + 1 : 0;
        }

        private AttackShape ChooseShape(float distance)
        {
            // Chained quicks are §6's signature for this shape, but an
            // enemy that only ever jabs never teaches the other two.
            if (_quickChain >= _profile.MaxQuickChain)
                return NextRoll() < _profile.CommittedWeightAfterChain
                    ? AttackShape.Committed
                    : AttackShape.Heavy;

            // Close in, the heavy and the committed are hard to escape, so
            // reaching for them at knife range is what makes standing still
            // punishing.
            var roll = NextRoll();
            if (distance <= _profile.PressureRange)
            {
                if (roll < _profile.QuickWeightClose) return AttackShape.Quick;
                if (roll < _profile.QuickWeightClose + _profile.HeavyWeightClose)
                    return AttackShape.Heavy;
                return AttackShape.Committed;
            }

            // At the edge of its reach it leans on the long, wide swings —
            // which is also the read that teaches a player to close or
            // leave rather than hover.
            if (roll < _profile.QuickWeightFar) return AttackShape.Quick;
            if (roll < _profile.QuickWeightFar + _profile.HeavyWeightFar)
                return AttackShape.Heavy;
            return AttackShape.Committed;
        }

        /// <summary>
        /// xorshift32. Deterministic, seedable, and the same on every
        /// platform — which a fight the server has to agree about needs,
        /// and which System.Random does not promise.
        /// </summary>
        private float NextRoll()
        {
            _state ^= _state << 13;
            _state ^= _state >> 17;
            _state ^= _state << 5;
            return (_state & 0xFFFFFFu) / (float)0x1000000;
        }
    }
}
