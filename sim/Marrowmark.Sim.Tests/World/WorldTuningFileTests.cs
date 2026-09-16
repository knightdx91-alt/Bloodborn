using System;
using System.IO;
using System.Reflection;
using System.Text.Json;
using Marrowmark.Sim.World;
using Xunit;

namespace Marrowmark.Sim.Tests.World
{
    /// <summary>
    /// Guards shared/tuning/world.json against drifting from DayProfile.
    /// Same reasoning as the combat and town guards: the prototype
    /// re-implements these rules in GDScript because Godot's web export
    /// cannot run C#, and duplicated tuning is a slow disaster.
    /// </summary>
    public class WorldTuningFileTests
    {
        private const string Canonical = "shared/tuning/world.json";
        private const string PrototypeCopy = "prototype/rules/world.json";

        private static string RepoRoot()
        {
            var dir = new DirectoryInfo(AppContext.BaseDirectory);
            while (dir != null && !File.Exists(Path.Combine(dir.FullName, Canonical)))
                dir = dir.Parent;
            Assert.True(dir != null, $"Could not find {Canonical}");
            return dir!.FullName;
        }

        [Fact]
        public void Day_tuning_matches_the_shared_file()
        {
            var root = JsonDocument
                .Parse(File.ReadAllText(Path.Combine(RepoRoot(), Canonical)))
                .RootElement;
            var profile = DayProfile.Default;

            foreach (var field in typeof(DayProfile).GetFields(
                         BindingFlags.Public | BindingFlags.Instance))
            {
                var key = char.ToLowerInvariant(field.Name[0]) + field.Name.Substring(1);
                JsonElement found = default;
                var hits = 0;
                foreach (var section in root.EnumerateObject())
                    if (section.Value.TryGetProperty(key, out var v)) { found = v; hits++; }

                Assert.True(hits == 1,
                    $"{key} appears {hits} times in {Canonical}; expected exactly 1");
                Assert.Equal((float)field.GetValue(profile)!, found.GetSingle(), 4);
            }
        }

        [Fact]
        public void The_prototype_copy_is_identical()
        {
            var a = File.ReadAllText(Path.Combine(RepoRoot(), Canonical));
            var b = File.ReadAllText(Path.Combine(RepoRoot(), PrototypeCopy));
            Assert.Equal(a.Replace("\r\n", "\n"), b.Replace("\r\n", "\n"));
        }
    }
}
