using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.Town;
using Xunit;

namespace Marrowmark.Sim.Tests.Town
{
    /// <summary>
    /// Guards shared/tuning/town.json against drifting from TownProfile.
    ///
    /// Same reasoning as TuningFileTests, and the same trap: Godot's web
    /// export cannot run C#, so the prototype re-implements these rules in
    /// GDScript and reads its numbers from that file. Duplicated logic is
    /// a cost taken knowingly; duplicated tuning is a slow disaster.
    ///
    /// By reflection on purpose — adding a field to TownProfile without
    /// adding it to the file fails here, which is exactly the case that
    /// would otherwise reach a playtest.
    /// </summary>
    public class TownTuningFileTests
    {
        private const string Canonical = "shared/tuning/town.json";

        /// <summary>The Godot project cannot load anything above res://.</summary>
        private const string PrototypeCopy = "prototype/rules/town.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;

            Assert.True(dir != null,
                $"Could not find {Canonical} above " + AppContext.BaseDirectory);
            return dir!.FullName;
        }

        private static JsonElement Load(string relative)
        {
            var text = File.ReadAllText(Path.Combine(RepoRoot(), relative));
            return JsonDocument.Parse(text).RootElement;
        }

        /// <summary>Every field of TownProfile must appear in exactly one
        /// section of the file, with the same value.</summary>
        [Fact]
        public void Town_tuning_matches_the_shared_file()
        {
            var root = Load(Canonical);
            var profile = TownProfile.Default;

            foreach (var field in typeof(TownProfile).GetFields(
                         BindingFlags.Public | BindingFlags.Instance))
            {
                var key = char.ToLowerInvariant(field.Name[0]) + field.Name.Substring(1);
                JsonElement found = default;
                var hits = 0;

                foreach (var section in root.EnumerateObject())
                    if (section.Value.TryGetProperty(key, out var v))
                    {
                        found = v;
                        hits++;
                    }

                Assert.True(hits == 1,
                    $"{key} appears {hits} times in {Canonical}; expected exactly 1");

                var expected = field.GetValue(profile);
                if (expected is float f)
                    Assert.Equal(f, found.GetSingle(), 5);
                else if (expected is int i)
                    Assert.Equal(i, found.GetInt32());
                else
                    Assert.Fail($"Unhandled field type for {key}: {field.FieldType}");
            }
        }

        [Fact]
        public void The_prototype_copy_is_identical()
        {
            var canonical = File.ReadAllText(Path.Combine(RepoRoot(), Canonical));
            var copy = File.ReadAllText(Path.Combine(RepoRoot(), PrototypeCopy));

            Assert.Equal(canonical.Replace("\r\n", "\n"), copy.Replace("\r\n", "\n"));
        }
    }
}
